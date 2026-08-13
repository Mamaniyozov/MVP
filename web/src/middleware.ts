import { NextResponse } from 'next/server'
import type { NextRequest } from 'next/server'

// Routes that don't require authentication
const publicRoutes = ['/login', '/register', '/forgot-password']
const publicPrefixes = ['/api/', '/_next/', '/favicon.ico']

export function middleware(request: NextRequest) {
  const { pathname } = request.nextUrl
  
  // Skip public static files and API routes
  if (publicPrefixes.some(prefix => pathname.startsWith(prefix))) {
    return NextResponse.next()
  }

  // Check if it's a public route
  const isPublicRoute = publicRoutes.includes(pathname)
  
  // Get token from cookies
  const hasAccessToken = request.cookies.has('access_token')
  const hasRefreshToken = request.cookies.has('refresh_token')
  
  const isAuthenticated = hasAccessToken || hasRefreshToken

  if (!isAuthenticated && !isPublicRoute && pathname !== '/') {
    // Redirect to login if trying to access a protected route without auth
    return NextResponse.redirect(new URL('/login', request.url))
  }

  if (isAuthenticated && isPublicRoute) {
    // Redirect to dashboard if trying to access login/register while authenticated
    return NextResponse.redirect(new URL('/dashboard', request.url))
  }

  return NextResponse.next()
}

export const config = {
  matcher: [
    /*
     * Match all request paths except for the ones starting with:
     * - api (API routes)
     * - _next/static (static files)
     * - _next/image (image optimization files)
     * - favicon.ico (favicon file)
     */
    '/((?!api|_next/static|_next/image|favicon.ico).*)',
  ],
}
