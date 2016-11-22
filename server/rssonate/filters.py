'''REST Filters used application-wide.'''
from rest_framework import filters


class CoalesceFilterBackend(filters.BaseFilterBackend):
    '''Support Ember Data coalesceFindRequests.'''
    def filter_queryset(self, request, queryset, view):
        id_list = request.query_params.getlist('ids[]')
        if id_list:
            queryset = queryset.filter(id__in=id_list)
        return queryset
