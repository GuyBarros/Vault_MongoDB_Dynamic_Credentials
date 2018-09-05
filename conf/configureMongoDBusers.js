db = connect('localhost:27017/admin');
db.createUser({user:'admin',pwd:'password',roles:[{role:'__system',db:'admin'}]});
db = connect('localhost:27017/vault_demo_db');
db.createUser({ user:'vault_admin',pwd:'r3ally5tr0ngPa55w0rd',roles:[{ role:'dbOwner',db:'vault_demo_db'}]});