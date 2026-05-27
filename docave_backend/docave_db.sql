-- ══════════════════════════════════════════════════════
-- DOCAVE - Base de datos MySQL
-- Ejecutar en phpMyAdmin o MySQL Workbench
-- ══════════════════════════════════════════════════════

CREATE DATABASE IF NOT EXISTS docave_db
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;

USE docave_db;

-- Django creará las tablas automáticamente con migrate,
-- pero aquí está la estructura de referencia:

-- Tabla de usuarios (la crea Django con AUTH_USER_MODEL)
CREATE TABLE IF NOT EXISTS users (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    password VARCHAR(128) NOT NULL,
    last_login DATETIME(6) NULL,
    is_superuser TINYINT(1) NOT NULL DEFAULT 0,
    username VARCHAR(150) NOT NULL UNIQUE,
    first_name VARCHAR(150) NOT NULL DEFAULT '',
    last_name VARCHAR(150) NOT NULL DEFAULT '',
    email VARCHAR(254) NOT NULL UNIQUE,
    is_staff TINYINT(1) NOT NULL DEFAULT 0,
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    date_joined DATETIME(6) NOT NULL,
    phone VARCHAR(20) NULL,
    avatar VARCHAR(100) NULL,
    bio LONGTEXT NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL
);

-- Tabla de categorías
CREATE TABLE IF NOT EXISTS categories (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    color VARCHAR(7) NOT NULL DEFAULT '#1A56FF',
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    UNIQUE KEY unique_user_category (user_id, name)
);

-- Tabla de tareas
CREATE TABLE IF NOT EXISTS tasks (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description LONGTEXT NULL,
    due_date DATE NOT NULL,
    due_time TIME(6) NOT NULL,
    is_completed TINYINT(1) NOT NULL DEFAULT 0,
    priority VARCHAR(10) NOT NULL DEFAULT 'medium',
    recurrence VARCHAR(10) NOT NULL DEFAULT 'none',
    tags VARCHAR(200) NULL,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    user_id BIGINT NOT NULL,
    category_id BIGINT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Tabla de notas
CREATE TABLE IF NOT EXISTS notes (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    content LONGTEXT NOT NULL,
    color VARCHAR(7) NOT NULL DEFAULT '#FFFFFF',
    is_pinned TINYINT(1) NOT NULL DEFAULT 0,
    created_at DATETIME(6) NOT NULL,
    updated_at DATETIME(6) NOT NULL,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- Tabla de recordatorios
CREATE TABLE IF NOT EXISTS reminders (
    id BIGINT AUTO_INCREMENT PRIMARY KEY,
    title VARCHAR(200) NOT NULL,
    description LONGTEXT NULL,
    remind_at DATETIME(6) NOT NULL,
    repeat VARCHAR(10) NOT NULL DEFAULT 'none',
    is_active TINYINT(1) NOT NULL DEFAULT 1,
    created_at DATETIME(6) NOT NULL,
    user_id BIGINT NOT NULL,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

-- ══════════════════════════════════════════════════════
-- Datos de prueba (opcional)
-- ══════════════════════════════════════════════════════
-- El usuario admin se crea con: python manage.py createsuperuser
