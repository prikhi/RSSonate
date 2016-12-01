from rest_framework.authtoken.models import Token
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import AllowAny
from rest_framework.response import Response

from .models import User


@api_view(['POST'])
@permission_classes([AllowAny])
def create_user(request):
    if request.method == 'POST':
        if (len(request.data['password']) > 0 and len(request.data['username']) > 0
                and request.data['password'] == request.data['password_again']):
            user = User.objects.create_user(username=request.data['username'],
                                            password=request.data['password'])
            (token, _) = Token.objects.get_or_create(user=user)
            return Response({"token": str(token)})
