# CalendarForWork Backend

Backend Node.js + Express cho app CalendarForWork, dùng MongoDB Atlas, JWT authentication và task CRUD.

## Chay du an

```bash
npm install
npm run dev
```

API mac dinh chay tai:

```text
http://localhost:3000
```

## Bien moi truong

Copy `.env.example` thanh `.env` va dien MongoDB URI/JWT secret rieng cua ban.

```bash
cp .env.example .env
```

Khong commit file `.env`.

## Auth API

### Dang ky

```http
POST /api/auth/register
Content-Type: application/json

{
  "username": "macvinh92",
  "email": "macvinh92@example.com",
  "password": "secret123"
}
```

### Dang nhap

```http
POST /api/auth/login
Content-Type: application/json

{
  "email": "macvinh92@example.com",
  "password": "secret123"
}
```

Response tra ve `token`. Gui token nay cho task API:

```http
Authorization: Bearer <token>
```

## Task API

Priority ho tro: `low`, `normal`, `high`, `urgent`.

Status ho tro: `new`, `in_progress`, `done`.

### Them cong viec

```http
POST /api/tasks
Authorization: Bearer <token>
Content-Type: application/json

{
  "name": "Hoan thanh backend",
  "priority": "urgent",
  "description": "Tao API cho ung dung CalendarForWork",
  "durationMinutes": 120,
  "time": {
    "hour": 14,
    "minute": 45,
    "day": 6,
    "month": 10,
    "year": 2026
  }
}
```

### Xem tat ca cong viec

```http
GET /api/tasks
Authorization: Bearer <token>
```

Co the loc:

```http
GET /api/tasks?status=in_progress&priority=urgent
```

### Xem chi tiet

```http
GET /api/tasks/:id
Authorization: Bearer <token>
```

### Chinh sua cong viec

```http
PATCH /api/tasks/:id
Authorization: Bearer <token>
Content-Type: application/json

{
  "status": "done",
  "priority": "high"
}
```

### Xoa cong viec

```http
DELETE /api/tasks/:id
Authorization: Bearer <token>
```

## Kiem thu

```bash
npm test
```
