from django.db import connection
from django.http import JsonResponse


def health_check(request):
    """
    Production-ready health check probe endpoint.
    Checks database connectivity without exposing sensitive internal credentials.
    """
    db_ok = True
    try:
        with connection.cursor() as cursor:
            cursor.execute("SELECT 1")
    except Exception:
        db_ok = False

    status_code = 200 if db_ok else 503
    return JsonResponse(
        {
            "status": "ok" if db_ok else "unhealthy",
            "database": "connected" if db_ok else "disconnected",
        },
        status=status_code,
    )
