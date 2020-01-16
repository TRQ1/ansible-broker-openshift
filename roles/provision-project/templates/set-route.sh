oc set triggers dc/egov-blue -n poc
oc set triggers dc/egov-green -n poc
oc expose svc/egov-blue --name=egov-bluegreen -n poc
oc patch route/egov-bluegreen -p '{"spec":{"to":{"name":"egov-green"}}}' -n poc
