
# There is a need to reformat this properly to get the it automated.
# Change the category tag if needed to separate another airflow repo for another usage.
# 1: tag it incrementally
# 2: automatically find the docker image with the latest built tag
# 3: push the correct tag into the hubble docker repo, but for the HUBBLE platform

# Local Tags
AIRFLOW_LOCAL_DOCKER='hubble/docker-airflow'
AIRFLOW_LOCAL_TAG='hubble-latest'
# AWS Tags
AIRFLOW_ECR_DOCKER='175416825336.dkr.ecr.ap-southeast-1.amazonaws.com/airflow'
AIRFLOW_CATEGORY='hubble'


# Set current tag based on the needed platform
# Change the filter at 'contains("delphi-") to the airflow category you need instead
AIRFLOW_CURRENT_ECR_TAG=\
$(aws ecr describe-images --output json --repository-name airflow --image-ids imageTag=$AIRFLOW_CATEGORY \
--query 'sort_by(imageDetails,& imagePushedAt)[-1].imageTags[*]' | jq -c '[.[] | select(contains("hubble-"))] | sort_by(.) | .[-1]' --raw-output)

# If first time run, this tag will be empty, thus set it to default
if [ -z "$AIRFLOW_CURRENT_ECR_TAG" ] || [ "$AIRFLOW_CURRENT_ECR_TAG" = "null" ]
then 
    AIRFLOW_CURRENT_ECR_TAG="$AIRFLOW_CATEGORY-1.0.0"
    echo "ECR Tag not set. Set as $AIRFLOW_CURRENT_ECR_TAG for now."
fi

# Next tag increment
AIRFLOW_NEXT_ECR_TAG=\
$(echo $AIRFLOW_CURRENT_ECR_TAG | awk -F. -v OFS=. 'NF==1{print ++$NF}; \
NF>1{if(length($NF+1)>length($NF))$(NF-1)++; $NF=sprintf("%0*d", length($NF), ($NF+1)%(10^length($NF))); print}')

echo "ECR Docker to push to: $AIRFLOW_ECR_DOCKER"
echo "ECR Tag currently on: $AIRFLOW_CURRENT_ECR_TAG"
echo "ECR Tag going next: $AIRFLOW_NEXT_ECR_TAG"
echo ""

case "$1" in
    # Pushes to the next increment tag - the code takes in only one digit separate by dots. e.g. 1.9.9 --> 2.0.0
    next)
        echo "Building Next Tag: $AIRFLOW_ECR_DOCKER:$AIRFLOW_NEXT_ECR_TAG"
        docker build --rm -t ${AIRFLOW_LOCAL_DOCKER}:${AIRFLOW_LOCAL_TAG} .
        $(aws ecr get-login --no-include-email --region ap-southeast-1)
        docker tag ${AIRFLOW_LOCAL_DOCKER}:${AIRFLOW_LOCAL_TAG} ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_NEXT_ECR_TAG}
        docker push ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_NEXT_ECR_TAG}
        docker tag ${AIRFLOW_LOCAL_DOCKER}:${AIRFLOW_LOCAL_TAG} ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_CATEGORY}
        docker push ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_CATEGORY}
        ;;

    # This does not work for me as it requires permission to delete tagged images in AWS ECR Docker.
    current) 
        echo "Building Current Tag: $AIRFLOW_ECR_DOCKER:$AIRFLOW_CURRENT_ECR_TAG"
        docker build --rm -t ${AIRFLOW_LOCAL_DOCKER}:${AIRFLOW_LOCAL_TAG} .
        $(aws ecr get-login --no-include-email --region ap-southeast-1)
        aws ecr batch-delete-image --repository-name ${AIRFLOW_ECR_DOCKER} --image-ids imageTag=${AIRFLOW_CURRENT_ECR_TAG}
        docker tag ${AIRFLOW_LOCAL_DOCKER}:${AIRFLOW_LOCAL_TAG} ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_CURRENT_ECR_TAG}
        docker push ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_CURRENT_ECR_TAG}
        docker tag ${AIRFLOW_LOCAL_DOCKER}:${AIRFLOW_LOCAL_TAG} ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_CATEGORY}
        docker push ${AIRFLOW_ECR_DOCKER}:${AIRFLOW_CATEGORY}
        ;;

    # Push the updated files to git as well
    git)
        echo "Pushing to git"
        read -e -p "Enter Your Commit Message: "  message
        git add .
        git commit -m "$message"
        git push
esac


