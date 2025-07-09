#!/bin/bash
 
# Environment Switch Script - Safe Version
# This script safely switches between blue and green environments for production and test
 
set -euo pipefail
 
NC='\033[0m'       # Text Reset
 
White='\033[0;37m'        # White
BWhite='\033[1;37m'       # White Bold
Grey='\033[1;30m'         # Grey
UGrey='\033[4;30m'         # Grey Underline
 
Blue='\033[0;34m'         # Blue
BBlue='\033[1;34m'        # Blue Bold
Green='\033[0;32m'        # Green
BGreen='\033[1;32m'       # Green Bold
 
Red='\033[0;31m'          # Red
BRed='\033[1;31m'         # Red Bold
Yellow='\033[0;33m'       # Yellow
BYellow='\033[1;33m'      # Yellow Bold
Purple='\033[0;35m'       # Purple
BPurple='\033[1;35m'      # Purple Bold
Cyan='\033[0;36m'         # Cyan
BCyan='\033[1;36m'        # Cyan Bold
 
EnvBlue='🔵'
EnvGreen='🟢'
Warning='⚠️'
Success='✅'
Failure='❌'
Info='ℹ️'
 
# Configuration
NAMESPACE="cadrart"
CONFIGMAP_NAME="environment-config"
TIMEOUT=30
 
# Check if kubectl is available
check_kubectl() {
  if ! command -v kubectl &> /dev/null; then
    echo -e ""
    echo -e "  ${Failure}${Red} kubectl is not installed or not in PATH${NC}"
    exit 1
  fi
}
 
# Check if namespace exists
check_namespace() {
  if ! kubectl get namespace "$NAMESPACE" &> /dev/null; then
    echo -e ""
    echo -e "  ${Failure}${Red} Namespace '$NAMESPACE' does not exist${NC}"
    exit 1
  fi
}
 
# Get current environment configuration
get_current_config() {
    local configmap_data
    configmap_data=$(kubectl get configmap "$CONFIGMAP_NAME" -n "$NAMESPACE" -o jsonpath='{.data}')
   
    if [[ -z "$configmap_data" ]]; then
        echo -e "  ${Failure}${Red} Could not retrieve environment configuration${NC}"
        exit 1
    fi
   
    echo "$configmap_data"
}
 
# Pass the prod environment color as parameter
# Ex: setEnvColors blue
setEnvColors() {
if [ $1 = 'blue' ]; then
    EnvProdBadge=${EnvBlue}
    EnvTestBadge=${EnvGreen}
    EnvProdColor='blue'
    EnvTestColor='green'
    EnvBlueType='PROD'
    EnvGreenType='TEST'
  else
    EnvProdBadge=${EnvGreen}
    EnvTestBadge=${EnvBlue}
    EnvProdColor='green'
    EnvTestColor='blue'
    EnvBlueType='TEST'
    EnvGreenType='PROD'
  fi
}
 
printCurrentStatus() {
  echo -e ""
  echo -e "${Grey}  ${Info}Current status:${NC}"
  echo -e "${White}    - ${EnvProdBadge} PROD${NC}"
  echo -e "${White}    - ${EnvTestBadge} TEST${NC}"
}
 
getEnvBadgeForColor() {
  if [ $1 = 'blue' ]; then
    echo ${EnvBlue}
  else
    echo ${EnvGreen}
  fi
}
 
getEnvTypeForColor() {
  if [ $1 = ${EnvProdColor} ]; then
    echo 'PROD'
  else
    echo 'TEST'
  fi
}
 
checkPodReadyness() {
    local color=$1
    local currentEnvBadge=$(getEnvBadgeForColor $color)
    local currentEnvType=$(getEnvTypeForColor $color)
    local frontend_pod
    local backend_pod
 
    frontend_pod=$(kubectl get pods -n "$NAMESPACE" -l "io.kompose.service=frontend-$color" -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")
   
    if [[ "$frontend_pod" != "Running" ]]; then
        echo -e "${Red}    ${Failure} ${currentEnvBadge} Frontend pod is not ready (status: $frontend_pod)${NC}"
        return 1
    fi
   
    backend_pod=$(kubectl get pods -n "$NAMESPACE" -l "io.kompose.service=backend-$color" -o jsonpath='{.items[*].status.phase}' 2>/dev/null || echo "")
   
    if [[ "$backend_pod" != "Running" ]]; then
        echo -e "${Red}    ${Failure} ${currentEnvBadge} Backend pod is not ready (status: $backend_pod)${NC}"
        return 1
    fi
   
    echo -e "${White}    ${Success} environment is ready${NC}"
    return 0
}
 
testBackend() {
    local color=$1
    local currentEnvBadge=$(getEnvBadgeForColor $color)
   
    # Test the actual environment service directly (not through proxy)
    local service_name="backend-$color"
   
    # Test the health endpoint
    local response
    local start_time
    start_time=$(date +%s)
   
    while true; do
        # Create a temporary pod for testing
        local pod_name="test-endpoint-$(date +%s)"
        kubectl run "$pod_name" --image=curlimages/curl -n "$NAMESPACE" -- curl -s -o /dev/null -w "%{http_code}" "http://$service_name:3000/api/health/live" >/dev/null 2>&1
        
        # Wait for pod to complete and get logs
        sleep 2
        response=$(kubectl logs "$pod_name" -n "$NAMESPACE" 2>/dev/null | grep -oE '^[0-9]+' || echo "000")
        
        # Clean up the pod
        kubectl delete pod "$pod_name" -n "$NAMESPACE" >/dev/null 2>&1
       
        # Color the response based on status
        local response_color
        if [[ "$response" == 200* ]]; then
            response_color=${Green}
        else
            response_color=${Red}
        fi
       
        echo -e  "${White}      - Response for backend: ${response_color}$response${NC}"
       
        # Accept if response starts with 200
        if [[ "$response" == 200* ]]; then
            return 0
        fi
       
        local current_time
        current_time=$(date +%s)
        local elapsed=$((current_time - start_time))
       
        if [[ $elapsed -gt $TIMEOUT ]]; then
            echo -e "${Yellow}      ${Warning} ${currentEnvBadge} backend is not responding after ${TIMEOUT}s (last response: $response)${NC}"
            return 1
        fi
       
        sleep 2
    done
}
 
testEnvironment() {
  local color=$1
  local currentEnvBadge=$(getEnvBadgeForColor $color)
  local currentEnvType=$(getEnvTypeForColor $color)
  local ready
  local backend
 
  echo -e ""
  echo -e "${Grey}  ${Info}Testing: ${currentEnvBadge} ${currentEnvType}${NC}"
  
  if checkPodReadyness $color; then
    ready=0
  else
    ready=1
  fi
  
  echo -e "${Grey}    - Testing: backend${NC}"
  
  if testBackend $color; then
    backend=0
  else
    backend=1
  fi
 
  if [ $ready -eq 0 ] && [ $backend -eq 0 ]; then
    return 0
  fi
 
  return 1
}
 
# Update proxy services to match new environment configuration
updateProxyServices() {
    local new_prod_color=$1
    local new_test_color=$2
   
    echo -e "${UGrey}  Updating proxy services...${NC}"
    
    # Update backend production proxy
    kubectl patch service backend-prod-proxy -n "$NAMESPACE" --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"backend-$new_prod_color\"}}}"
    echo -e "${White}    - backend-prod-proxy → backend-$new_prod_color${NC}"
    
    # Update backend test proxy
    kubectl patch service backend-test-proxy -n "$NAMESPACE" --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"backend-$new_test_color\"}}}"
    echo -e "${White}    - backend-test-proxy → backend-$new_test_color${NC}"
    
    # Update frontend production proxy
    kubectl patch service frontend-prod-proxy -n "$NAMESPACE" --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"frontend-$new_prod_color\"}}}"
    echo -e "${White}    - frontend-prod-proxy → frontend-$new_prod_color${NC}"
    
    # Update frontend test proxy
    kubectl patch service frontend-test-proxy -n "$NAMESPACE" --type='merge' -p="{\"spec\":{\"selector\":{\"io.kompose.service\":\"frontend-$new_test_color\"}}}"
    echo -e "${White}    - frontend-test-proxy → frontend-$new_test_color${NC}"
}

# Switch environment roles
switchEnvironmentRoles() {
    local new_prod_color=$1
    local new_test_color=$2
   
    echo -e "${UGrey}  Switching environment roles:${NC}"
    kubectl patch configmap "$CONFIGMAP_NAME" -n "$NAMESPACE" --type='merge' -p="{\"data\":{\"COLOR_PROD\":\"$new_prod_color\",\"COLOR_TEST\":\"$new_test_color\"}}"
    
    # Update proxy services to match new configuration
    updateProxyServices "$new_prod_color" "$new_test_color"
    
    # Set colors for display
    setEnvColors $new_prod_color
    echo -e "${White}  - Production: ${EnvProdBadge}${NC}"
    echo -e "${White}  - Test: ${EnvTestBadge}${NC}"
}
 
# Main function
main() {
  echo -e "${UGrey}Start Environments Switch${NC}"
 
  # Pre-flight checks
  check_kubectl
  check_namespace
 
  # Get current configuration
  local current_config
  current_config=$(get_current_config)
  local current_prod current_test
  current_prod=$(echo "$current_config" | jq -r '.COLOR_PROD')
  current_test=$(echo "$current_config" | jq -r '.COLOR_TEST')
 
  setEnvColors ${current_prod}
  printCurrentStatus
 
  # Test both environments
  local blue_ready=false
  local green_ready=false
  
  if testEnvironment blue; then
    blue_ready=true
  fi
  
  if testEnvironment green; then
    green_ready=true
  fi
   
  # Determine new configuration
  local new_prod new_test
  if [[ "$current_prod" == "blue" ]]; then
    new_prod="green"
    new_test="blue"
  else
    new_prod="blue"
    new_test="green"
  fi
  
  if [[ "$blue_ready" == "false" || "$green_ready" == "false" ]]; then
    echo ""
    echo -e "${Yellow}    ${Warning}  Do you want to proceed with the switch anyway?${NC}"
    echo -e "${Yellow}      This will change:"
    echo -e "${Yellow}      - ${EnvGreen} will become ${EnvBlueType}${NC}"
    echo -e "${Yellow}      - ${EnvBlue} will become ${EnvGreenType}${NC}"
    echo
    read -p "Type 'yes' to proceed: " confirmation
   
    if [[ "$confirmation" != "yes" ]]; then
      echo -e "${Red} Switch cancelled by user${NC}"
      exit 0
    fi
  fi
   
  # Perform the switch
  switchEnvironmentRoles "$new_prod" "$new_test"
 
  echo -e "${UGrey}  Verifying switch...${NC}"
  local new_config
  new_config=$(get_current_config)
 
  echo -e "${UGrey}    New configuration:${NC}"
  local new_prod_actual new_test_actual
  new_prod_actual=$(echo "$new_config" | jq -r '.COLOR_PROD')
  new_test_actual=$(echo "$new_config" | jq -r '.COLOR_TEST')
  setEnvColors ${new_prod_actual}
  printCurrentStatus
 
  echo -e "${Green} Environment switch completed successfully!${NC}"
}
 
# Handle script arguments
case "${1:-}" in
    "status")
        check_kubectl
        check_namespace
        current_config=$(get_current_config)
        current_prod=$(echo "$current_config" | jq -r '.COLOR_PROD')
        setEnvColors ${current_prod}
        printCurrentStatus
        ;;
    "test")
        check_kubectl
        check_namespace
        current_config=$(get_current_config)
        current_prod=$(echo "$current_config" | jq -r '.COLOR_PROD')
        setEnvColors ${current_prod}
        printCurrentStatus
        testEnvironment blue
        testEnvironment green
        ;;
    "switch"|"")
        main
        ;;
    *)
        echo "Usage: $0 [status|test|switch]"
        echo "  status  - Show current environment configuration"
        echo "  test    - Test current environment health"
        echo "  switch  - Switch environment roles (default)"
        exit 1
        ;;
esac