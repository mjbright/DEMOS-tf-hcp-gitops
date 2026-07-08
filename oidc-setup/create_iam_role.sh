
die() { echo "$0: die - $*" >&2; exit 1; }

#AWS_ACCOUNT_ID=$( aws sts get-caller-identity | jq -r '.Account' )
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

HCP_ORG_NAME="mjbright-Consulting"

[ -z "$AWS_ACCOUNT_ID" ] && die "Failed to get account id"

#sed \
#  -e "s/AWS_ACCOUNT_ID/$AWS_ACCOUNT_ID/" \
#  -e "s/HCP_ORG_NAME/$HCP_ORG_NAME/" \
#  < iam.role.json.template > iam.role.json

cat > terraform.tfvars <<-EOF
  hcp_terraform_organization = "$HCP_ORG_NAME"
  aws_account_id             = "$AWS_ACCOUNT_ID"
EOF

terraform init
terraform apply

ROLE_ARN=$(terraform output -raw iam_role_arn)
echo "IAM Role ARN: $ROLE_ARN"

