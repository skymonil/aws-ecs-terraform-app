import { useState, FormEvent, ChangeEvent, useEffect } from "react";
import logo from "../assets/logo.jpeg";
import axios from "axios";
import { API_ROUTES } from "../utils/apiConfig";

interface FormData {
  username: string;
  email: string;
  password: string;
}

interface College {
  _id: string;
  collegeName: string;
}

const Register: React.FC = () => {
  const [formData, setFormData] = useState<FormData>({
    username: "",
    email: "",
    password: "",
  });

  const [confirmPassword, setConfirmPassword] = useState("");
  const [college, setCollege] = useState<string>("");
  const [colleges, setColleges] = useState<College[]>([]);
  const [error, setError] = useState<string | null>(null);
  const [passwordVisible, setPasswordVisible] = useState(false);
  const [isModalOpen, setIsModalOpen] = useState(false);
  const [otp, setOtp] = useState("");
  const [otpError, setOtpError] = useState("");
  const [loading, setLoading] = useState(false);

  useEffect(() => {
    const fetchColleges = async () => {
      try {
        setLoading(true);
        const response = await axios.get(API_ROUTES.getColleges);
        
        // ✅ FIX: Properly handle the API response
        console.log("Colleges API Response:", response.data);
        
        // Check if response.data is an array
        if (Array.isArray(response.data)) {
          setColleges(response.data);
        } 
        // If response has a data property that's an array
        else if (Array.isArray(response.data.data)) {
          setColleges(response.data.data);
        }
        // If response has a colleges property that's an array
        else if (Array.isArray(response.data.colleges)) {
          setColleges(response.data.colleges);
        }
        else {
          console.error("Unexpected API response structure:", response.data);
          setError("Failed to load colleges list");
          setColleges([]); // Set empty array to prevent map error
        }
      } catch (error) {
        console.error("Error fetching colleges:", error);
        setError("Failed to fetch colleges");
        setColleges([]); // Set empty array to prevent map error
      } finally {
        setLoading(false);
      }
    };

    fetchColleges();
  }, []);

  const handleRegister = async (e: FormEvent) => {
    e.preventDefault();
    
    if (!college) {
      setError("Please select a college");
      return;
    }

    const registerData = {
      ...formData,
      collegeId: college,
    };

    try {
      console.log("registerData: ", registerData);
      const response = await axios.post(API_ROUTES.studentRegister, registerData);
      console.log("User registered: ", response.data);
      setIsModalOpen(true);
      setError(null); // Clear any previous errors
    } catch (error: any) {
      console.error("Registration error:", error);
      if (error.response?.data) {
        const backendErrors = error.response.data.errors || error.response.data.error;
        setError(
          Array.isArray(backendErrors)
            ? backendErrors.map((err: any) => err.msg || err).join(", ")
            : backendErrors
        );
      } else {
        setError("An unexpected error occurred. Please try again.");
      }
    }
  };

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault();
    if (formData.password !== confirmPassword) {
      setError("Passwords do not match!");
      setTimeout(() => setError(null), 3000);
      return;
    }
    handleRegister(e);
  };

  const handleChange = (e: ChangeEvent<HTMLInputElement>) => {
    const { name, value } = e.target;
    setFormData({ ...formData, [name]: value });
  };

  const handleOtpSubmit = async () => {
    try {
      const trimmedOtp = otp.trim();
      if (!trimmedOtp) {
        setOtpError("Please enter OTP");
        return;
      }

      const response = await axios.post(API_ROUTES.studentOtpVerify, { 
        email: formData.email, 
        otp: trimmedOtp 
      });
      
      console.log("OTP verification successful:", response.data);
      window.location.href = "/log-in";
    } catch (error: any) {
      console.error("OTP verification error:", error);
      setOtpError(error.response?.data?.message || "Invalid OTP or OTP has expired");
    }
  };

  return (
    <div className="flex items-center justify-center h-screen bg-gray-100">
      <div className="flex w-full max-w-4xl bg-white rounded-lg shadow-lg overflow-hidden">
        {/* Left side with logo */}
        <div className="hidden lg:flex lg:w-1/2 items-center justify-center bg-gray-50 p-4">
          <img src={logo} alt="Logo" className="object-contain" />
        </div>

        {/* Right side with form */}
        <div className="w-full lg:w-1/2 p-6 space-y-3">
          <h2 className="text-2xl font-semibold text-center text-gray-800">
            CREATE ACCOUNT IN STAGING2
          </h2>
          <p className="text-center text-gray-600 text-sm">
            Join us today to get started
          </p>
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label htmlFor="username" className="block text-sm font-medium text-gray-700">
                Username
              </label>
              <input
                type="text"
                id="username"
                name="username"
                className="w-full px-4 py-2 mt-2 text-gray-700 bg-gray-100 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#9c231b]"
                value={formData.username}
                onChange={handleChange}
                required
              />
            </div>
            <div>
              <label htmlFor="email" className="block text-sm font-medium text-gray-700">
                Email Address
              </label>
              <input
                type="email"
                id="email"
                name="email"
                className="w-full px-4 py-2 mt-2 text-gray-700 bg-gray-100 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#9c231b]"
                value={formData.email}
                onChange={handleChange}
                required
              />
            </div>
            <div>
              <label htmlFor="password" className="block text-sm font-medium text-gray-700">
                Password
              </label>
              <div className="relative">
                <input
                  type={passwordVisible ? "text" : "password"}
                  id="password"
                  name="password"
                  className="w-full px-4 py-2 text-gray-700 bg-gray-100 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#9c231b]"
                  value={formData.password}
                  onChange={handleChange}
                  required
                />
                {passwordVisible ? (
                  <i
                    className="fa-solid fa-eye absolute top-1/2 right-3 transform -translate-y-1/2 cursor-pointer text-gray-500"
                    onClick={() => setPasswordVisible(!passwordVisible)}
                  ></i>
                ) : (
                  <i
                    className="fa-solid fa-eye-slash absolute top-1/2 right-3 transform -translate-y-1/2 cursor-pointer text-gray-500"
                    onClick={() => setPasswordVisible(!passwordVisible)}
                  ></i>
                )}
              </div>
            </div>
            <div>
              <label htmlFor="confirm-password" className="block text-sm font-medium text-gray-700">
                Confirm Password
              </label>
              <div className="relative">
                <input
                  type="password"
                  id="confirm-password"
                  className="w-full px-4 py-2 text-gray-700 bg-gray-100 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#9c231b]"
                  value={confirmPassword}
                  onChange={(e) => setConfirmPassword(e.target.value)}
                  required
                />
              </div>
            </div>
            <div>
              <label htmlFor="college" className="block text-sm font-medium text-gray-700">
                College
              </label>
              <select
                id="college"
                name="college"
                className="w-full px-4 py-2 mt-2 text-gray-700 bg-gray-100 border border-gray-300 rounded-lg focus:outline-none focus:ring-2 focus:ring-[#9c231b]"
                value={college}
                onChange={(e) => setCollege(e.target.value)}
                required
                disabled={loading}
              >
                <option value="">Select a college</option>
                {/* ✅ FIX: Safe mapping with fallback */}
                {Array.isArray(colleges) && colleges.map((clg) => (
                  <option key={clg._id} value={clg._id}>
                    {clg.collegeName}
                  </option>
                ))}
              </select>
              {loading && <p className="text-sm text-gray-500 mt-1">Loading colleges...</p>}
            </div>
            <div className="flex justify-end">
              <button
                type="submit"
                className="w-full px-6 py-2 text-white bg-[#9c231b] rounded-lg hover:bg-[#502b28] focus:outline-none focus:ring-2 focus:ring-black disabled:opacity-50"
                disabled={loading}
              >
                {loading ? "Loading..." : "Register"}
              </button>
            </div>
          </form>
          {error && <p className="text-red-500 text-center mt-2">{error}</p>}
          <div className="text-center">
            <span className="text-sm text-gray-600">
              Already have an account?{" "}
            </span>
            <button
              className="text-[#9c231b] hover:underline focus:outline-none"
              onClick={() => (window.location.href = "/log-in")}
            >
              Login here
            </button>
          </div>
        </div>
      </div>

      {/* OTP Modal */}
      {isModalOpen && (
        <div className="fixed inset-0 bg-gray-600 bg-opacity-50 flex items-center justify-center">
          <div className="bg-white p-6 rounded-lg w-80">
            <h3 className="text-lg font-semibold mb-4">Enter OTP</h3>
            <p className="text-sm text-gray-600 mb-4">
              We've sent an OTP to your email: {formData.email}
            </p>
            <input
              type="text"
              className="w-full p-2 border border-gray-300 rounded-lg mb-4"
              placeholder="Enter OTP"
              value={otp}
              onChange={(e) => {
                setOtp(e.target.value);
                setOtpError(""); // Clear error when user types
              }}
              maxLength={6}
            />
            {otpError && (
              <p className="text-red-500 text-center text-sm pb-4">
                {otpError}
              </p>
            )}
            <div className="flex justify-between">
              <button
                className="px-4 py-2 bg-gray-300 rounded-lg hover:bg-gray-400"
                onClick={() => setIsModalOpen(false)}
              >
                Cancel
              </button>
              <button
                className="px-4 py-2 bg-[#9c231b] text-white rounded-lg hover:bg-[#502b28]"
                onClick={handleOtpSubmit}
              >
                Verify OTP
              </button>
            </div>
          </div>
        </div>
      )}
    </div>
  );
};

export default Register;