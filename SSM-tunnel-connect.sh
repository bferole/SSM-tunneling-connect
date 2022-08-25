unset  AWS_ACCESS_KEY_ID
unset  AWS_SECRET_ACCESS_KEY
unset  AWS_SESSION_TOKEN
export AWS_REGION="eu-north-1"
export AWS_ROLE_ARN="arn:aws:iam::XXXXXXXX-ACCNR:role/XXXXX-cross_account_assume_role"
export LOCAL_PORT="22" #LOCALHOST SSH PORT
export REMOTE_PORT="22" #Remote SSH port (to bastion-host)

#SET INSTANCE NAME
#read -p "Instance name? (Press Enter for default): " INSTANCE_NAME
INSTANCE_NAME=${INSTANCE_NAME:-default-dev} #standard server
echo "Connecting to "$INSTANCE_NAME
export INSTANCE_NAME

# IF no Profile
#temp_role=$(aws sts assume-role \
#                    --role-arn $AWS_ROLE_ARN \
#                    --role-session-name "session-manager-port-forward")

# IF Profile
temp_role=$(aws sts assume-role \
                    --role-arn $AWS_ROLE_ARN \
                    --role-session-name "session-manager-port-forward" --profile awscustomeraccess)

# Uses jq as dependancy, possible to refactor to use sed for generalization
export AWS_ACCESS_KEY_ID=$(echo $temp_role | jq -r .Credentials.AccessKeyId)
export AWS_SECRET_ACCESS_KEY=$(echo $temp_role | jq -r .Credentials.SecretAccessKey)
export AWS_SESSION_TOKEN=$(echo $temp_role | jq -r .Credentials.SessionToken)

printf "\nOpen SSH and connect \n"
echo "NOTE: You can jump to another server from" $INSTANCE_NAME "if needed"

instance_id=$(aws ec2 describe-instances \
    --filters "Name=tag:Name,Values=$INSTANCE_NAME" \
    --query "Reservations[*].Instances[*].[InstanceId]" --output text)

aws ssm start-session --target $instance_id --document-name AWS-StartPortForwardingSession --parameters '{"portNumber":["'${REMOTE_PORT}'"], "localPortNumber":["'${LOCAL_PORT}'"]}' --region $AWS_REGION


unset  AWS_ACCESS_KEY_ID
unset  AWS_SECRET_ACCESS_KEY
unset  AWS_SESSION_TOKEN

read 