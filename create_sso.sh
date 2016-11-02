#yum -y install java-1.8.0-openjdk
#yum -y pwgen
rm -r -f ${1}idm
mkdir ${1}idm
cd ${1}idm
#pwgen 8 1 > .password
echo 'password' > .password
export idmpassword=$(cat .password)
oc new-project ${1}idm
oc create serviceaccount sso-service-account
oadm policy add-role-to-user admin gwest
oc policy add-role-to-user view system:serviceaccount:idm:sso-service-account
echo "Stage 1 - REQ"
openssl req -new -passout file:.password -newkey rsa:4096 -x509 -keyout xpaas.key -out xpaas.crt -days 365 -subj "/CN=xpaas-sso.ca"
echo "Stage 2 - GENKEYPAIR"
keytool  -genkeypair -storepass file:.password -keypass file:.password -keyalg RSA -keysize 2048 -dname "CN=idm.${1}.rsc7.com" -alias sso-https-key -keystore sso-https.jks
echo "Stage 3 - CERTREQ"
keytool  -storepass file:.password -keypass file:.password -certreq -keyalg rsa -alias sso-https-key -keystore sso-https.jks -file sso.csr
echo "Stage 4 - X509"
openssl x509 -req -passin file:.password -CA xpaas.crt -CAkey xpaas.key -in sso.csr -out sso.crt -days 365 -CAcreateserial
echo "Stage 5 - IMPORT CRT"
keytool  -import -file xpaas.crt  -storepass file:.password -keypass file:.password -alias xpaas.ca -keystore sso-https.jks
echo "Stage 6 - IMPORT SSO"
keytool  -storepass file:.password -keypass file:.password  -import -file sso.crt -alias sso-https-key -keystore sso-https.jks
echo "Stage 7 - IMPORT XPAAS"
keytool -storepass file:.password -keypass file:.password   -import -file xpaas.crt -alias xpaas.ca -keystore truststore.jks
echo "Stage 8 - GENSECKEY"
keytool  -storepass file:.password -keypass file:.password -genseckey -alias jgroups -storetype JCEKS -keystore jgroups.jceks
echo "Stage 9 - OCCREATE SECRET"
oc create secret generic sso-app-secret --from-file=jgroups.jceks --from-file=sso-https.jks --from-file=truststore.jks
echo "Stage 10 - OCCREATE SECRET ADD"
oc secret add sa/sso-service-account secret/sso-app-secret
echo "Stage 11 - Create App"
oc new-app sso70-https -n openshift -p \
      APPLICATION_NAME=sso,\
      HOSTNAME_HTTPS=secureidm.${1}.rsc7.com,\
      HOSTNAME_HTTP=idm.${1}.rsc7.com,\
      HTTPS_KEYSTORE=sso-https.jks,\
      HTTPS_PASSWORD=${idmpassword},\
      HTTPS_SECRET=sso-app-secret,\
      JGROUPS_ENCRYPT_KEYSTORE=jgroups.jceks,\
      JGROUPS_ENCRYPT_PASSWORD=${idmpassword},\
      JGROUPS_ENCRYPT_SECRET=sso-app-secret,\
      SERVICE_ACCOUNT_NAME=sso-service-account,\
      SSO_REALM=cloud,\
      SSO_SERVICE_USERNAME=sso-mgmtuser,\
      SSO_SERVICE_PASSWORD=mgmt-password,\
      SSO_ADMIN_USERNAME=admin,\
      SSO_ADMIN_PASSWORD=adm-password,\
      SSO_TRUSTSTORE=truststore.jks,\
      SSO_TRUSTSTORE_PASSWORD=${idmpassword}