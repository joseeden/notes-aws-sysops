# aws ssm get-parameters
aws ssm get-parameters --names /rds/db1
# return encrypted/unencrypted values
aws ssm get-parameters --names encrypted-parameter
aws ssm get-parameters --names encrypted-parameter --with-decryption
# return by path
aws ssm get-parameters-by-path --path /rds