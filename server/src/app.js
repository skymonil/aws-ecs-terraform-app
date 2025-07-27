import express from "express";
import cors from "cors";
import { connectDB } from "./lib/db.js";
import cookieParser from "cookie-parser";
import dotenv from "dotenv";
import bodyParser from "body-parser";
import authRoute from "./routes/auth.route.js";
import accountantRoute from "./routes/accountant.route.js";
import grievanceRoute from "./routes/grievance.route.js";
import leaveRoute from "./routes/leave.route.js";
import collegeRoute from "./routes/college.routes.js";
import studentRoute from "./routes/student.route.js";
import adminRoute from "./routes/admin.route.js";
import scholarshipRoute from './routes/scholarship.route.js'
import razopayRoute from "./routes/razopay.route.js";
import courseRoute from "./routes/course.route.js";
import teacherRoute from "./routes/teacher.route.js";

const app = express();
const PORT = 5000;

dotenv.config();
connectDB();

app.use( cors({
    origin: "http://localhost:5173",
    credentials: true,
  })
);
app.use(cookieParser());
app.use(express.urlencoded({ extended: true }));
app.use(bodyParser.json());
app.use(express.json());

app.use("/api/auth", authRoute);
app.use("/api/student", studentRoute);
app.use("/api/admin", adminRoute);
app.use("/api/college", collegeRoute);
app.use("/api/admin/accountant", accountantRoute); //Endpoint to Add Money to Student Wallet from Accountant Side
app.use("/api/grievance", grievanceRoute); //Endpoint to Add Grievance from Student side and Resolve Grievance from HOD side
app.use("/api/leave", leaveRoute); //Endpoint to Add Leave from Student side and Approve or Reject Leave from HOD side
app.use("/api/razopay", razopayRoute); //Endpoint to Add Money to Student Wallet from Student Side using Razorpay
app.use("/api/course", courseRoute);
app.use('/api/scholarship',scholarshipRoute);
app.use('/api/teacher',teacherRoute);

app.listen(PORT, () => {
  console.log(`Server is running on : ${PORT}`);
});
