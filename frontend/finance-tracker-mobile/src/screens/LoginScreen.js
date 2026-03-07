import React, { useState } from "react";
import {
View,
Text,
TextInput,
TouchableOpacity,
StyleSheet,
Alert
} from "react-native";

import AsyncStorage from "@react-native-async-storage/async-storage";
import { loginUser } from "../services/authService";

export default function LoginScreen({ navigation }) {

const [email, setEmail] = useState("");
const [password, setPassword] = useState("");

const handleLogin = async () => {

try {

const data = await loginUser(email, password);

await AsyncStorage.setItem("token", data.access_token);

navigation.replace("Dashboard");

} catch (error) {

Alert.alert("Login Failed");

}

};

return (

<View style={styles.container}>

<Text style={styles.title}>AI Finance Tracker</Text>

<View style={styles.card}>

<TextInput
style={styles.input}
placeholder="Email"
value={email}
onChangeText={setEmail}
/>

<TextInput
style={styles.input}
placeholder="Password"
secureTextEntry
value={password}
onChangeText={setPassword}
/>

<TouchableOpacity
style={styles.button}
onPress={handleLogin}
>

<Text style={styles.buttonText}>Login</Text>

</TouchableOpacity>

<TouchableOpacity
onPress={() => navigation.navigate("Register")}
>

<Text style={styles.link}>
Create Account
</Text>

</TouchableOpacity>

</View>

</View>

);
}

const styles = StyleSheet.create({

container: {
flex: 1,
justifyContent: "center",
backgroundColor: "#F1F5F9",
padding: 20
},

title: {
fontSize: 28,
fontWeight: "bold",
textAlign: "center",
marginBottom: 40,
color: "#1E3A8A"
},

card: {
backgroundColor: "#FFFFFF",
padding: 25,
borderRadius: 14,
shadowColor: "#000",
shadowOpacity: 0.08,
shadowRadius: 10,
elevation: 4
},

input: {
borderWidth: 1,
borderColor: "#CBD5E1",
padding: 14,
borderRadius: 10,
marginBottom: 15,
backgroundColor: "#F8FAFC"
},

button: {
backgroundColor: "#2563EB",
padding: 15,
borderRadius: 10,
alignItems: "center"
},

buttonText: {
color: "#FFFFFF",
fontSize: 16,
fontWeight: "bold"
},

link: {
marginTop: 15,
textAlign: "center",
color: "#2563EB",
fontWeight: "600"
}

});