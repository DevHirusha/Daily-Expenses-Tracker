# Daily Expenses Tracker

Daily Expenses Tracker, also branded as PocketCrew in the Flutter app, is a
full-stack expense and budget management application. It includes a Flutter
client for end users, a Spring Boot REST API, and a React/Vite administration
panel.

This repository is intended to be run locally with MySQL. No hosted database
or hosted application service is required.

## Features

- User registration, login, JWT authentication, email verification, and password reset
- Personal budgets, categories, expenses, spending summaries, and savings goals
- Shared budgets, groups, members, settlements, and proof uploads
- Friend requests and friend lists
- Gig listings and gig applications
- Admin management for users, gigs, gig applications, and announcements

## Repository layout

```text
.
├── Backend/          Spring Boot API and MySQL persistence
├── Frontend/         Flutter mobile, web, and desktop client
└── admin-frontend/   React/Vite admin panel
```

## Technology stack

- Backend: Java 21, Spring Boot, Spring Security, Spring Data JPA, Maven
- Database: MySQL 8 or newer
- User client: Flutter/Dart
- Admin client: React 19, Vite, Axios, Tailwind CSS

## Prerequisites

Install the following before starting:

- Java Development Kit (JDK) 21
- MySQL Server 8 or newer and a MySQL client
- Flutter SDK with Dart 3.10.4 or newer
- Node.js 20 or newer and npm
- Git

The backend includes Maven Wrapper scripts, so a separate Maven installation is
not required.

## 1. Clone the repository

```bash
git clone <repository-url>
cd Daily-Expenses-Tracker
```

Replace `<repository-url>` with the URL of the version-controlled repository
containing this project.

## 2. Create the local MySQL database

Start the local MySQL service, then create a database. The application can
create the database automatically when the configured MySQL user has permission,
but creating it explicitly makes the setup easier to verify.

```sql
CREATE DATABASE daily_expenses
  CHARACTER SET utf8mb4
  COLLATE utf8mb4_unicode_ci;
```

Using a dedicated local user is recommended:

```sql
CREATE USER 'daily_expenses_user'@'localhost' IDENTIFIED BY 'change-this-password';
GRANT ALL PRIVILEGES ON daily_expenses.* TO 'daily_expenses_user'@'localhost';
FLUSH PRIVILEGES;
```

If the database user already exists, only grant it access to the database.

## 3. Configure and run the backend

The backend reads database and application settings from environment variables.
Its local defaults are:

| Setting | Default |
| --- | --- |
| API host | `localhost` |
| API port | `8080` |
| Database host | `localhost` |
| Database port | `3306` |
| Database name | `daily_expenses` |
| Database user | `root` |
| Database password | empty |
| Hibernate schema mode | `update` |

For a dedicated MySQL user, set the values before starting the backend.

PowerShell:

```powershell
$env:DB_HOST = "localhost"
$env:DB_PORT = "3306"
$env:DB_DATABASE = "daily_expenses"
$env:DB_USERNAME = "daily_expenses_user"
$env:DB_PASSWORD = "change-this-password"
$env:SERVER_PORT = "8080"
```

macOS/Linux:

```bash
export DB_HOST=localhost
export DB_PORT=3306
export DB_DATABASE=daily_expenses
export DB_USERNAME=daily_expenses_user
export DB_PASSWORD=change-this-password
export SERVER_PORT=8080
```

Run the API from the repository root:

PowerShell:

```powershell
cd Backend
.\mvnw.cmd spring-boot:run
```

macOS/Linux:

```bash
cd Backend
./mvnw spring-boot:run
```

The API base URL is `http://localhost:8080/api/v1.0`.

### Local administrator account

On first startup, the backend creates a local super administrator when the
account does not already exist:

| Field | Default |
| --- | --- |
| Email | `superadmin@dailyexpenses.local` |
| Username | `superadmin` |
| Password | `Admin@12345` |

Override these before starting the backend when needed:

```powershell
$env:SUPER_ADMIN_EMAIL = "admin@example.local"
$env:SUPER_ADMIN_USERNAME = "admin"
$env:SUPER_ADMIN_NAME = "Local Admin"
$env:SUPER_ADMIN_PASSWORD = "change-this-admin-password"
```

These defaults are for local development only. Do not use them for a shared or
public deployment.

### Optional email configuration

Email sending is disabled by default, so the application can run locally
without an SMTP server. To enable welcome emails and OTP messages, configure
the following environment variables before starting the backend:

```powershell
$env:MAIL_ENABLED = "true"
$env:MAIL_HOST = "smtp.example.com"
$env:MAIL_PORT = "587"
$env:MAIL_USERNAME = "your-smtp-user"
$env:MAIL_PASSWORD = "your-smtp-password"
$env:MAIL_SMTP_AUTH = "true"
$env:MAIL_SMTP_STARTTLS = "true"
$env:MAIL_FROM = "no-reply@example.com"
```

## 4. Run the Flutter client

Open a second terminal:

```bash
cd Frontend
flutter pub get
flutter devices
```

For Flutter Web or a desktop target on the same computer as the backend:

```bash
flutter run -d chrome
```

For an Android emulator, use the emulator host alias instead of
`localhost`:

```bash
flutter run -d <android-device-id> \
  --dart-define=API_BASE_URL=http://10.0.2.2:8080/api/v1.0
```

For a physical device, replace `YOUR_PC_IP` with the computer's LAN IP and
make sure the device can reach port 8080:

```bash
flutter run -d <device-id> \
  --dart-define=API_BASE_URL=http://YOUR_PC_IP:8080/api/v1.0
```

The API URL is defined in `Frontend/lib/services/api_service.dart` and can be
overridden without changing source code using `API_BASE_URL`.

## 5. Run the React admin panel

Open another terminal:

```bash
cd admin-frontend
npm ci
npm run dev
```

Open the URL printed by Vite, normally `http://localhost:5173`, then sign in
with the local administrator account. The admin panel defaults to
`http://localhost:8080` for API requests.

To use a different backend URL, create `admin-frontend/.env.local`:

```dotenv
VITE_API_URL=http://localhost:8080
```

`.env.local` is ignored by Git and should not contain credentials committed to
the repository.

## Verification commands

Backend tests:

PowerShell:

```powershell
cd Backend
.\mvnw.cmd test
```

macOS/Linux:

```bash
cd Backend
./mvnw test
```

Admin lint and production build:

```bash
cd admin-frontend
npm run lint
npm run build
```

Flutter analysis and tests:

```bash
cd Frontend
flutter analyze
flutter test
```

## Troubleshooting

- **Cannot connect to MySQL:** confirm the MySQL service is running, the database exists, and `DB_USERNAME`/`DB_PASSWORD` match the local account.
- **Port 8080 is busy:** set `SERVER_PORT` to another port and update both client API URLs.
- **Android emulator cannot reach the API:** use `10.0.2.2` instead of `localhost`.
- **Physical device cannot reach the API:** use the host computer's LAN IP and allow the selected port through the local firewall.
- **OTP or welcome emails do not arrive:** email is disabled by default; configure SMTP variables or use a local SMTP test server.
- **Admin login is rejected:** verify that the backend started successfully and that the bootstrap account has an `ADMIN` or `SUPER_ADMIN` role.

## Version-control and security notes

- Commit source code, configuration templates, and documentation to the
  repository; do not commit passwords, API keys, or private SMTP credentials.
- Keep local overrides in environment variables or ignored `.env.local` files.
- The backend uses Hibernate `ddl-auto=update` for local development. Use a
  reviewed migration strategy before production use.
