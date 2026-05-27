from rest_framework import generics, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework_simplejwt.tokens import RefreshToken
from django.contrib.auth import authenticate
from .models import User
from .serializers import RegisterSerializer, UserProfileSerializer, ChangePasswordSerializer


class RegisterView(generics.CreateAPIView):
    queryset = User.objects.all()
    serializer_class = RegisterSerializer
    permission_classes = [AllowAny]

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        user = serializer.save()
        refresh = RefreshToken.for_user(user)
        return Response({
            'message': 'Usuario registrado exitosamente.',
            'user': UserProfileSerializer(user).data,
            'access': str(refresh.access_token),
            'refresh': str(refresh),
        }, status=status.HTTP_201_CREATED)


@api_view(['POST'])
@permission_classes([AllowAny])
def login_view(request):
    username = request.data.get('username')
    password = request.data.get('password')

    if not username or not password:
        return Response({'detail': 'Usuario y contraseña requeridos.'}, status=400)

    # Permite login con email o username
    user = None
    if '@' in username:
        try:
            u = User.objects.get(email=username)
            user = authenticate(request, username=u.username, password=password)
        except User.DoesNotExist:
            pass
    else:
        user = authenticate(request, username=username, password=password)

    if user is None:
        return Response({'detail': 'Usuario o contraseña incorrectos.'}, status=401)

    refresh = RefreshToken.for_user(user)
    return Response({
        'access': str(refresh.access_token),
        'refresh': str(refresh),
        'user': UserProfileSerializer(user).data,
    })


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def logout_view(request):
    try:
        refresh_token = request.data.get('refresh')
        token = RefreshToken(refresh_token)
        token.blacklist()
        return Response({'message': 'Sesión cerrada correctamente.'})
    except Exception:
        return Response({'message': 'Sesión cerrada.'})


class ProfileView(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


@api_view(['POST'])
@permission_classes([IsAuthenticated])
def change_password_view(request):
    serializer = ChangePasswordSerializer(data=request.data, context={'request': request})
    serializer.is_valid(raise_exception=True)
    request.user.set_password(serializer.validated_data['new_password'])
    request.user.save()
    return Response({'message': 'Contraseña actualizada correctamente.'})


@api_view(['GET'])
@permission_classes([IsAuthenticated])
def stats_view(request):
    user = request.user
    tasks = user.tasks.all()
    total = tasks.count()
    completed = tasks.filter(is_completed=True).count()
    pending = tasks.filter(is_completed=False).count()
    notes = user.notes.count()
    reminders = user.reminders.count()
    return Response({
        'total_tasks': total,
        'completed_tasks': completed,
        'pending_tasks': pending,
        'completion_rate': round((completed / total * 100), 1) if total > 0 else 0,
        'total_notes': notes,
        'total_reminders': reminders,
    })
