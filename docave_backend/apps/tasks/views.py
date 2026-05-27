from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from django.utils import timezone
from .models import Task, Category
from .serializers import TaskSerializer, CategorySerializer


class CategoryViewSet(viewsets.ModelViewSet):
    serializer_class = CategorySerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Category.objects.filter(user=self.request.user)


class TaskViewSet(viewsets.ModelViewSet):
    serializer_class = TaskSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        qs = Task.objects.filter(user=self.request.user)
        # Filtros opcionales por query params
        date = self.request.query_params.get('date')
        priority = self.request.query_params.get('priority')
        category = self.request.query_params.get('category')
        completed = self.request.query_params.get('completed')
        search = self.request.query_params.get('search')

        if date:
            qs = qs.filter(due_date=date)
        if priority:
            qs = qs.filter(priority=priority)
        if category:
            qs = qs.filter(category__name__icontains=category)
        if completed is not None:
            qs = qs.filter(is_completed=completed.lower() == 'true')
        if search:
            qs = qs.filter(title__icontains=search)
        return qs

    @action(detail=True, methods=['patch'])
    def toggle(self, request, pk=None):
        task = self.get_object()
        task.is_completed = not task.is_completed
        task.save()
        return Response(TaskSerializer(task).data)

    @action(detail=False, methods=['get'])
    def today(self, request):
        today = timezone.localdate()
        tasks = Task.objects.filter(user=request.user, due_date=today)
        return Response(TaskSerializer(tasks, many=True).data)

    @action(detail=False, methods=['get'])
    def pending(self, request):
        tasks = Task.objects.filter(user=request.user, is_completed=False)
        return Response(TaskSerializer(tasks, many=True).data)

    @action(detail=False, methods=['get'])
    def stats(self, request):
        tasks = Task.objects.filter(user=request.user)
        total = tasks.count()
        completed = tasks.filter(is_completed=True).count()
        by_priority = {
            'high': tasks.filter(priority='high').count(),
            'medium': tasks.filter(priority='medium').count(),
            'low': tasks.filter(priority='low').count(),
        }
        return Response({
            'total': total,
            'completed': completed,
            'pending': total - completed,
            'completion_rate': round(completed / total * 100, 1) if total > 0 else 0,
            'by_priority': by_priority,
        })
