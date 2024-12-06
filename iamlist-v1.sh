#!/bin/bash

# Check if AWS profile is provided
if [ -z "$1" ]; then
  echo "Usage: $0 <AWS_PROFILE>"
  exit 1
fi

AWS_PROFILE=$1

# File containing role names (one per line)
ROLE_LIST="roles.txt"

# Directory to store role policy folders
OUTPUT_DIR="role_policies"

# Create output directory if it doesn't exist
mkdir -p "$OUTPUT_DIR"

# Loop through each role
while IFS= read -r ROLE_NAME; do
  echo "Processing role: $ROLE_NAME"
  
  # Create a directory for the role
  ROLE_DIR="$OUTPUT_DIR/$ROLE_NAME"
  mkdir -p "$ROLE_DIR"
  
  # Get attached policies
  ATTACHED_POLICIES=$(aws iam list-attached-role-policies --profile "$AWS_PROFILE" --role-name "$ROLE_NAME" --query 'AttachedPolicies[*]' --output json)
  
  # Parse attached policies
  echo "$ATTACHED_POLICIES" | grep -o '"PolicyName":"[^"]*","PolicyArn":"[^"]*"' | while IFS= read -r POLICY; do
    POLICY_NAME=$(echo "$POLICY" | sed -n 's/.*"PolicyName":"\([^"]*\)".*/\1/p')
    POLICY_ARN=$(echo "$POLICY" | sed -n 's/.*"PolicyArn":"\([^"]*\)".*/\1/p')
    
    # Fetch policy document
    POLICY_VERSION=$(aws iam get-policy --profile "$AWS_PROFILE" --policy-arn "$POLICY_ARN" --query 'Policy.DefaultVersionId' --output text)
    POLICY_DOCUMENT=$(aws iam get-policy-version --profile "$AWS_PROFILE" --policy-arn "$POLICY_ARN" --version-id "$POLICY_VERSION" --query 'PolicyVersion.Document' --output json)
    
    # Save to file
    echo "$POLICY_DOCUMENT" > "$ROLE_DIR/$POLICY_NAME.json"
    echo "  Saved attached policy: $POLICY_NAME"
  done
  
  # Get inline policies
  INLINE_POLICY_NAMES=$(aws iam list-role-policies --profile "$AWS_PROFILE" --role-name "$ROLE_NAME" --query 'PolicyNames' --output json)
  
  # Parse inline policies
  echo "$INLINE_POLICY_NAMES" | sed -e 's/[][]//g' -e 's/"//g' | tr ',' '\n' | while IFS= read -r INLINE_POLICY; do
    if [ -n "$INLINE_POLICY" ]; then
      INLINE_POLICY_DOCUMENT=$(aws iam get-role-policy --profile "$AWS_PROFILE" --role-name "$ROLE_NAME" --policy-name "$INLINE_POLICY" --query 'PolicyDocument' --output json)
      
      # Save to file
      echo "$INLINE_POLICY_DOCUMENT" > "$ROLE_DIR/$INLINE_POLICY.json"
      echo "  Saved inline policy: $INLINE_POLICY"
    fi
  done
  
done < "$ROLE_LIST"

echo "All policies have been saved to $OUTPUT_DIR"