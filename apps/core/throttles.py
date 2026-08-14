from rest_framework.throttling import UserRateThrottle

class LoginRateThrottle(UserRateThrottle):
    rate = '5/hour'
    scope = 'login'

class RegisterRateThrottle(UserRateThrottle):
    rate = '3/hour'
    scope = 'register'
