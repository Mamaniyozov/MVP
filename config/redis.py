from redis.cluster import RedisCluster
from django_redis.client import DefaultClient

class RedisClusterClient(DefaultClient):
    """
    Custom client class for django-redis to support Redis Cluster.
    Overrides the connect method to use RedisCluster instead of strict Redis.
    """
    def connect(self, index):
        """Override the connection retrieval function."""
        # Use the connection string provided in settings
        return RedisCluster.from_url(self._server[index])
