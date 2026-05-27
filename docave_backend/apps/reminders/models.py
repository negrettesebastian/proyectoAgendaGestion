from django.db import models
from django.conf import settings

class Reminder(models.Model):
    REPEAT_CHOICES = [
        ('none', 'Sin repetición'),
        ('daily', 'Diario'),
        ('weekly', 'Semanal'),
        ('monthly', 'Mensual'),
    ]

    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name='reminders')
    title = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)
    remind_at = models.DateTimeField()
    repeat = models.CharField(max_length=10, choices=REPEAT_CHOICES, default='none')
    is_active = models.BooleanField(default=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'reminders'
        ordering = ['remind_at']

    def __str__(self):
        return self.title
