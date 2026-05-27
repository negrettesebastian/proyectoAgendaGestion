from django.contrib import admin
from .models import Task, Category

@admin.register(Category)
class CategoryAdmin(admin.ModelAdmin):
    list_display = ['name', 'color', 'user']
    search_fields = ['name']

@admin.register(Task)
class TaskAdmin(admin.ModelAdmin):
    list_display = ['title', 'user', 'due_date', 'due_time', 'priority', 'is_completed', 'category']
    list_filter = ['is_completed', 'priority', 'recurrence']
    search_fields = ['title', 'description']
    date_hierarchy = 'due_date'
