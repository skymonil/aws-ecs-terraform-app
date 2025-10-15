import College from "../models/College.model.js";
import crypto from "crypto";

const generateHash = (data) => {
  return crypto.createHash("sha1").update(data).digest("hex");
};

export const addCollege = async (req, res) => {
  const { collegeID, collegeName, address, globalFees, courses } = req.body;

  try {
    const existingCollege = await College.findOne({ collegeID });
    if (existingCollege) {
      return res.status(400).json({ message: "College ID already exists." });
    }

    const newCollege = new College({
      collegeID,
      collegeName,
      address,
      globalFees: globalFees.map((fee) => ({
        title: fee.title,
        amount: fee.amount,
      })),
      courses: courses.map((course) => ({
        courseName: course.courseName,
        eligibility: course.eligibility,
        baseFee: course.baseFee,
        subject: course.subjects.map((subject) => ({
          subjectName: subject.name,
          marks: {
            min: subject.minMarks,
            max: subject.maxMarks,
          },
        })),
      })),
    });

    // Save to database
    await newCollege.save();
    res.status(201).json({ message: "College added successfully." });
  } catch (error) {
    console.error("Error adding college:", error);
    res.status(500).json({ message: "Failed to add college." });
  }
};

const sendCachedResponse = (req, res, data) => {
  const jsonData = JSON.stringify(data);
  const etag = generateHash(jsonData);

  res.set("Cache-Control", "public, s-maxage=600, max-age=60");


  res.status(200).json(data);
};

export const getCollege = async (req, res) => {
  try {
    const colleges = await College.find();

    return sendCachedResponse(req, res, colleges);

    res.status(200).json(colleges);
  } catch (error) {
    res.status(500).json({ message: "Error fetching colleges", error });
  }
};

export const getColleges = async (req, res) => {
  try {
    const colleges = await College.find({}, "_id collegeName");
   
    if (!colleges || colleges.length === 0) {
      return res.status(404).json({ message: "No colleges found" });
    }

  return sendCachedResponse(req, res, colleges);
  } catch (error) {
    console.error("Error fetching colleges: ", error);
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const getCollegeById = async (req, res) => {
  try {
    const collegeId = req.params.id;
    console.log("Id: ", collegeId);

    const college = await College.findById(collegeId);

    if (!collegeId || collegeId.length === 0) {
      return res
        .status(404)
        .json({ message: "College not found for Id: " + collegeId });
    }

    res.status(200).json(college);
  } catch (error) {
    console.error("Error fetching college by id: ", error);
    res.status(500).json({ message: "Internal server error", error });
  }
};

export const getAllCourses = async (req, res) => {
  try {
    const college = await College.findOne({}, "courses");

    if (!college || !college.courses || college.courses.length === 0) {
      return res.status(404).json({ message: "No courses found" });
    }

    res.status(200).json(college.courses);
  } catch (error) {
    console.error("Error fetching courses: ", error);
    res.status(500).json({ message: "Internal server error", error });
  }
};
