#/bin/bash
#updating the current image used by the pod
kubectl rollout restart deployment yelb-appserver yelb-ui yelb-db
