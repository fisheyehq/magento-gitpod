#!/bin/bash
sleep 12;
mysql -u root -pnem4540 -e 'CREATE DATABASE IF NOT EXISTS magento2;' &&
url=$(gp url | awk -F"//" {'print $2'}) && url+="/" && 
url="https://8002-"$url && 
if [ "${INSTALL_MAGENTO}" = "YES" ]; then php bin/magento setup:install --db-name='magento2' --db-user='root' --db-password='nem4540' --base-url=$url --backend-frontname='admin' --admin-user=$MAGENTO_ADMIN_USERNAME --admin-password=$MAGENTO_ADMIN_PASSWORD --admin-email=$GITPOD_GIT_USER_EMAIL --admin-firstname='Admin' --admin-lastname='User' --use-rewrites='1' --use-secure='1' --base-url-secure=$url --use-secure-admin='1' --language='en_GB' --db-host='127.0.0.1' --cleanup-database --timezone='Europe/London' --currency='GBP' --session-save='redis'; fi &&

# Copy composer credentials to auth.json to allow non-interactive install of sample data and additional Commerce modules
sed -i "s/AUTH_USER/${MAGENTO_COMPOSER_AUTH_USER}/g" ${GITPOD_REPO_ROOT}/auth.json &&
sed -i "s/AUTH_PASS/${MAGENTO_COMPOSER_AUTH_PASS}/g" ${GITPOD_REPO_ROOT}/auth.json &&

if [ "${MAGENTO_EDITION}" = "enterprise" ]; then composer require magento/extension-b2b; fi &&
if [ "${INSTALL_SAMPLE_DATA}" = "YES" ]; then n98-magerun2 sampledata:deploy; fi &&
n98-magerun2 module:enable --all &&
n98-magerun2 module:disable Magento_Csp Magento_TwoFactorAuth &&
n98-magerun2 setup:upgrade &&

yes | php bin/magento setup:config:set --session-save=redis --session-save-redis-host=127.0.0.1 --session-save-redis-log-level=3 --session-save-redis-db=0 --session-save-redis-port=6379;
yes | php bin/magento setup:config:set --cache-backend=redis --cache-backend-redis-server=127.0.0.1 --cache-backend-redis-db=1;
yes | php bin/magento setup:config:set --page-cache=redis --page-cache-redis-server=127.0.0.1 --page-cache-redis-db=2;

n98-magerun2 config:store:set web/cookie/cookie_path "/" &&
n98-magerun2 config:store:set web/cookie/cookie_domain ".gitpod.io" &&

if [ "${MAGENTO_EDITION}" = "enterprise" ]; then
	n98-magerun2 config:store:set btob/website_configuration/company_active "1"
	n98-magerun2 config:store:set btob/website_configuration/sharedcatalog_active "1"
	n98-magerun2 config:store:set btob/website_configuration/negotiablequote_active "1"
	n98-magerun2 config:store:set btob/website_configuration/quickorder_active "1"
	n98-magerun2 config:store:set btob/website_configuration/requisition_list_active "1"
	n98-magerun2 config:store:set btob/default_b2b_payment_methods/available_payment_methods "braintree_ach_direct_debit,braintree_applepay,banktransfer,cashondelivery,checkmo,braintree,payflow_advanced,payflow_link,payflowpro,braintree_googlepay,braintree_local_payment,free,braintree_paypal,paypal_billing_agreement,payflow_express_bml,paypal_express_bml,paypal_express,payflow_express,hosted_pro,companycredit,purchaseorder,braintree_paypal_vault,braintree_cc_vault,payflowpro_cc_vault,braintree_venmo"
	n98-magerun2 config:store:set btob/default_b2b_shipping_methods/applicable_shipping_methods "0"
	n98-magerun2 config:store:set btob/website_configuration/purchaseorder_enabled "1"
	n98-magerun2 config:store:set catalog/magento_catalogpermissions/enabled "1"
	n98-magerun2 config:store:set catalog/magento_catalogpermissions/grant_catalog_category_view "1"
	n98-magerun2 config:store:set catalog/magento_catalogpermissions/grant_catalog_product_price "1"
	n98-magerun2 config:store:set catalog/magento_catalogpermissions/grant_checkout_items "1"
	n98-magerun2 config:store:set sales/product_sku/my_account_enable "1"
fi &&


n98-magerun2 cache:flush &&
redis-cli flushall &&

#Use this section to import a staging DB instead of using the default blank M2
#cd $GITPOD_REPO_ROOT/gitpod && unzip magento-db.sql.zip && 
#url=$(gp url | awk -F"//" {'print $2'}) && url="8002-"$url && sed -i 's#staging-domain.com#'$url'#g' magento-db.sql && 
#mysql -uroot -pnem4540 magento2 < magento-db.sql && 
#cd $GITPOD_REPO_ROOT && ./bin/magento setup:upgrade && 
#mysql -u root -pnem4540 -e 'use magento2; update core_config_data set value = 8 where path = "design/theme/theme_id";' &&
#n98-magerun2 cache:flush &&

touch $GITPOD_REPO_ROOT/gitpod/db-installed.flag
