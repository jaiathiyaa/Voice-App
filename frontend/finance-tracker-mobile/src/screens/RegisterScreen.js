import React, { useState } from "react";
import {
View,
Text,
TextInput,
TouchableOpacity,
StyleSheet,
Alert
} from "react-native";

import { registerUser } from "../services/authService";

export default function RegisterScreen({ navigation }) {

const [email, setEmail] = useState("");
const [password, setPassword] = useState("");

const handleRegister = async () => {

try {

await registerUser(email, password);

Alert.alert("Registration Successful");

navigation.navigate("Login");

} catch (error) {

Alert.alert("Registration Failed");

}

};

return (

<View style={styles.container}>

<Text style={styles.title}>Create Account</Text>

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
onPress={handleRegister}
>

<Text style={styles.buttonText}>Register</Text>

</TouchableOpacity>

<TouchableOpacity
onPress={() => navigation.goBack()}
>

<Text style={styles.link}>
Back to Login
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