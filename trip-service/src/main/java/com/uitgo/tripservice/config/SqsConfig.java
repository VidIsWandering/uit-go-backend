package com.uitgo.tripservice.config;

import com.amazonaws.auth.AWSStaticCredentialsProvider;
import com.amazonaws.auth.BasicAWSCredentials;
import com.amazonaws.client.builder.AwsClientBuilder;
import com.amazonaws.services.sqs.AmazonSQSAsync;
import com.amazonaws.services.sqs.AmazonSQSAsyncClientBuilder;
import io.awspring.cloud.messaging.core.QueueMessagingTemplate;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.context.annotation.Primary;

@Configuration
public class SqsConfig {

    @Value("${cloud.aws.region.static:ap-southeast-1}")
    private String region;

    @Value("${AWS_SQS_ENDPOINT:#{null}}")
    private String sqsEndpoint;

    @Value("${cloud.aws.credentials.access-key:test}")
    private String accessKey;

    @Value("${cloud.aws.credentials.secret-key:test}")
    private String secretKey;

    @Bean
    @Primary
    public AmazonSQSAsync amazonSQSAsync() {
        BasicAWSCredentials awsCredentials = new BasicAWSCredentials(accessKey, secretKey);
        AmazonSQSAsyncClientBuilder builder = AmazonSQSAsyncClientBuilder.standard()
                .withCredentials(new AWSStaticCredentialsProvider(awsCredentials));
        
        if (sqsEndpoint != null && !sqsEndpoint.isEmpty()) {
            // LocalStack: use the same region as queue creation
            builder.withEndpointConfiguration(
                new AwsClientBuilder.EndpointConfiguration(sqsEndpoint, region)
            );
        } else {
            builder.withRegion(region);
        }
        
        return builder.build();
    }

    @Bean
    public QueueMessagingTemplate queueMessagingTemplate(AmazonSQSAsync amazonSQSAsync) {
        return new QueueMessagingTemplate(amazonSQSAsync);
    }
}
