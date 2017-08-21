#http://blog.keycloak.org/2016/10/registering-new-clients-from-shell.html
mypod=`oc get pods | grep "sso-1" | cut -d " " -f1`
#        * SSO Admin Username=admin
#        * SSO Admin Password=adm-password
sso_admin_username="admin"
sso_admin_password="adm-password"
sso_domain="cloud"
rsh $mypod kcreg.sh config credentials --server http://localhost:8180/auth --realm master --user admin --password admin --secret db2cd162-aa86-4154-a16e-a393c9db4f76

