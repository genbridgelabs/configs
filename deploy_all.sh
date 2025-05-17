#!/bin/bash

# Define an array of project names and their GitLab URLs
projects=(
  "ennomart-eureka-server https://gitlab.com/ennomart/ennomart-eureka-server.git"
  "ennomart-apigateway https://gitlab.com/ennomart/ennomart-apigateway.git"
  "ennomart-buyer https://gitlab.com/ennomart/ennomart-buyer.git"
  "ennomart-core https://gitlab.com/ennomart/ennomart-core.git"
  "ennomart-gateway-hub https://gitlab.com/ennomart/ennomart-gateway-hub.git"
  "ennomart-notification https://gitlab.com/ennomart/ennomart-notification.git"
  "ennomart-product https://gitlab.com/ennomart/ennomart-product.git"
  "ennomart-report https://gitlab.com/ennomart/ennomart-report.git"
  # "ennomart-hrm https://gitlab.com/ennomart/ennomart-hrm.git"
  # "ennomart-inventory-management https://gitlab.com/ennomart/ennomart-inventory-management.git"
  # "ennomart-invoice https://gitlab.com/ennomart/ennomart-invoice.git"
  # "ennomart-fe https://gitlab.com/ennomart/ennomart-fe.git"
  # "ennomart-frontend https://gitlab.com/Ennomart-FrontEnd/ennomart-frontend.git"
)

# Iterate over each project and deploy it
for project in "${projects[@]}"; do
  /home/script/deploy_project.sh $project
  if [ $? -ne 0 ]; then
    echo "Deployment failed for $project, continuing..."
  else
    echo "Successfully deployed $project"
  fi
done

echo "Deployment process completed!"
