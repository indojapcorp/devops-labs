// index.js - Lambda function to process messages from SQS

exports.handler = async (event) => {
    console.log('Received event:', JSON.stringify(event, null, 2));
    
    // Process each record from SQS
    for (const record of event.Records) {
        try {
            // Parse the message body
            const body = JSON.parse(record.body);
            
            // If this is from SNS, the actual message is nested
            let message;
            if (record.eventSource === 'aws:sqs' && body.Type === 'Notification') {
                message = JSON.parse(body.Message);
            } else {
                message = body;
            }
            
            console.log('Processing message:', JSON.stringify(message, null, 2));
            
            // Do some processing with the message
            // This is where your business logic would go
            
            console.log('Successfully processed message');
        } catch (error) {
            console.error('Error processing message:', error);
            // In a production environment, you might want to send this to the DLQ
            // but LocalStack will automatically retry based on the SQS configuration
        }
    }
    
    return {
        statusCode: 200,
        body: JSON.stringify({ message: 'Messages processed successfully' }),
    };
};
