import API from "./api";

export const registerUser = async (email, password) => {
  const response = await API.post("/register", {
    email,
    password
  });

  return response.data;
};

export const loginUser = async (email, password) => {

  const formData = new URLSearchParams();
  formData.append("username", email);
  formData.append("password", password);

  const response = await API.post("/login", formData, {
    headers: {
      "Content-Type": "application/x-www-form-urlencoded"
    }
  });

  return response.data;
};