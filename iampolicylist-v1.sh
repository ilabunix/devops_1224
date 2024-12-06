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
  ATTACHED_POLICIES=$(aws iam list-attached-role-policies --role-name "$ROLE_NAME" --profile "$AWS_PROFILE" --query 'AttachedPolicies[*]' --output json)
  
  # Debug attached policies
  echo "Attached Policies for $ROLE_NAME: $ATTACHED_POLICIES"
  
  echo "$ATTACHED_POLICIES" | grep -o '"PolicyName":"[^"]*","PolicyArn":"[^"]*"' | while IFS= read -r POLICY; do
    POLICY_NAME=$(echo "$POLICY" | sed -n 's/.*"PolicyName":"\([^"]*\)".*/\1/p')
    POLICY_ARN=$(echo "$POLICY" | sed -n 's/.*"PolicyArn":"\([^"]*\)".*/\1/p')
    
    # Fetch policy document
    POLICY_VERSION=$(aws iam get-policy --policy-arn "$POLICY_ARN" --profile "$AWS_PROFILE" --query 'Policy.DefaultVersionId' --output text)
    POLICY_DOCUMENT=$(aws iam get-policy-version --policy-arn "$POLICY_ARN" --version-id "$POLICY_VERSION" --profile "$AWS_PROFILE" --query 'PolicyVersion.Document' --output json)
    
    # Save to file
    if [ -n "$POLICY_DOCUMENT" ]; then
      echo "$POLICY_DOCUMENT" > "$ROLE_DIR/$POLICY_NAME.json"
      echo "  Saved attached policy: $POLICY_NAME"
    else
      echo "  No attached policy document found for: $POLICY_NAME"
    fi
  done
  
  # Get inline policies
  INLINE_POLICY_NAMES=$(aws iam list-role-policies --role-name "$ROLE_NAME" --profile "$AWS_PROFILE" --query 'PolicyNames' --output json)
  
  # Debug inline policies
  echo "Inline Policies for $ROLE_NAME: $INLINE_POLICY_NAMES"
  
  echo "$INLINE_POLICY_NAMES" | sed -e 's/[][]//g' -e 's/"//g' | tr ',' '\n' | while IFS= read -r INLINE_POLICY; do
    if [ -n "$INLINE_POLICY" ]; then
      INLINE_POLICY_DOCUMENT=$(aws iam get-role-policy --role-name "$ROLE_NAME" --policy-name "$INLINE_POLICY" --profile "$AWS_PROFILE" --query 'PolicyDocument' --output json)
      
      # Save to file
      if [ -n "$INLINE_POLICY_DOCUMENT" ]; then
        echo "$INLINE_POLICY_DOCUMENT" > "$ROLE_DIR/$INLINE_POLICY.json"
        echo "  Saved inline policy: $INLINE_POLICY"
      else
        echo "  No inline policy document found for: $INLINE_POLICY"
      fi
    fi
  done
  
done < "$ROLE_LIST"

echo "All policies have been saved to $OUTPUT_DIR"