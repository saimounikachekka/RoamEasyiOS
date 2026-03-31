require("dotenv").config();
const express = require('express');
const app = express();
const AWS = require("aws-sdk");
const cors = require("cors");

// Configure AWS DynamoDB
AWS.config.update({
    region: process.env.AWS_REGION,
});

const port = process.env.PORT || 8080;

const dynamoDB = new AWS.DynamoDB.DocumentClient();
const TABLE_NAME_IOS = process.env.DYNAMO_DB_TABLE_IOS;

const corsOptions = {
  origin: '*', // or specify allowed origins
  methods: ['GET', 'POST', 'DELETE'], // allow these methods
  allowedHeaders: ['Content-Type'],
};

app.use(express.json());
app.use(cors(corsOptions));

app.get('/', (req, res) => {
    res.send("hello world!")
});

app.get("/ios/saved-places", async (req, res) => {
    const { userId } = req.query;

    if (!userId) {
        return res.status(400).json({ error: "userId is required" });
    }

    const params = {
        TableName: TABLE_NAME_IOS,
        KeyConditionExpression: "userId = :userId",
        ExpressionAttributeValues: {
            ":userId": userId,
        },
    };

    try {
        const data = await dynamoDB.query(params).promise();
        res.json(data.Items);
    } catch (error) {
        res.status(500).json({ error: `Failed to get items: ${error.message}` });
    }
});

app.post("/ios/saved-places", async (req, res) => {
    const { userId, placeId, city, country, imageUrl, placeName } = req.body;

    if (!userId || !placeId) {
        return res.status(400).json({ error: "userId and placeId are required" });
    }

    const params = {
        TableName: TABLE_NAME_IOS,
        Item: {
            userId,
            placeId,
            city,
            country,
            imageUrl,
            placeName,
        },
    };

    try {
        await dynamoDB.put(params).promise();
        res.json({ message: "Place saved successfully" });
    } catch (error) {
        res.status(500).json({ error: `Failed to save place: ${error.message}` });
    }
});

app.delete("/ios/saved-places", async (req, res) => {
    const { userId, placeId } = req.body;

    if (!userId || !placeId) {
        return res.status(400).json({ error: "userId and placeId are required" });
    }

    const params = {
        TableName: TABLE_NAME_IOS,
        Key: { userId, placeId },
    };

    try {
        await dynamoDB.delete(params).promise();
        res.json({ message: `Place ${placeId} for user ${userId} removed successfully.` });
    } catch (error) {
        res.status(500).json({ error: `Failed to remove place: ${error.message}` });
    }
});

app.listen(port, () => {
    console.log(`Server running on http://localhost:${port}`);
});
