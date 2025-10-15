import mongoose from "mongoose";
import dotenv from "dotenv";

dotenv.config();

export const connectDB = async () => {
  try {
    const uri = process.env.MONGODB_URI;
    if (!uri) throw new Error("MongoDB connection URI is missing!");

    const conn = await mongoose.connect(uri, {
      maxPoolSize: 50,  // Maximum number of sockets in the pool
      minPoolSize: 10,  // Keep 10 connections alive
      serverSelectionTimeoutMS: 5000,  // Timeout for initial connection
      socketTimeoutMS: 45000,  // Timeout for operations
    });

    console.log(`MongoDB Connected: ${conn.connection.host}`);
    console.log(`Connection Pooling Enabled (min: 10, max: 50)`);
  } catch (err) {
    console.error("MongoDB connection error:", err);
  }
};
