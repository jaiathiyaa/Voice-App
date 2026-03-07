import React, { useEffect, useState } from "react";
import {
View,
Text,
StyleSheet,
ScrollView
} from "react-native";

import AsyncStorage from "@react-native-async-storage/async-storage";
import API from "../services/api";

export default function DashboardScreen() {

const [summary, setSummary] = useState({});
const [health, setHealth] = useState({});

useEffect(() => {

fetchData();

}, []);

const fetchData = async () => {

try {

const token = await AsyncStorage.getItem("token");

const summaryRes = await API.get(
"/transactions/summary",
{
headers: { Authorization: `Bearer ${token}` }
}
);

const healthRes = await API.get(
"/transactions/health-score",
{
headers: { Authorization: `Bearer ${token}` }
}
);

setSummary(summaryRes.data);
setHealth(healthRes.data);

} catch (error) {

console.log(error);

}

};

return (

<ScrollView style={styles.container}>

<Text style={styles.title}>
Dashboard
</Text>

<View style={styles.balanceCard}>

<Text style={styles.balanceText}>
Balance
</Text>

<Text style={styles.balanceAmount}>
₹{summary.balance || 0}
</Text>

</View>

<View style={styles.row}>

<View style={styles.cardIncome}>

<Text style={styles.cardTitle}>
Income
</Text>

<Text style={styles.cardAmount}>
₹{summary.total_income || 0}
</Text>

</View>

<View style={styles.cardExpense}>

<Text style={styles.cardTitle}>
Expense
</Text>

<Text style={styles.cardAmount}>
₹{summary.total_expense || 0}
</Text>

</View>

</View>

<View style={styles.healthCard}>

<Text style={styles.healthTitle}>
Financial Health Score
</Text>

<Text style={styles.healthScore}>
{health.health_score || 0}
</Text>

</View>

</ScrollView>

);
}

const styles = StyleSheet.create({

container: {
flex: 1,
backgroundColor: "#F1F5F9",
padding: 20
},

title: {
fontSize: 28,
fontWeight: "bold",
marginBottom: 20,
color: "#1E3A8A"
},

balanceCard: {
backgroundColor: "#2563EB",
padding: 25,
borderRadius: 16,
marginBottom: 20
},

balanceText: {
color: "#fff",
fontSize: 18
},

balanceAmount: {
color: "#fff",
fontSize: 30,
fontWeight: "bold",
marginTop: 5
},

row: {
flexDirection: "row",
justifyContent: "space-between",
marginBottom: 20
},

cardIncome: {
backgroundColor: "#DCFCE7",
flex: 1,
padding: 20,
borderRadius: 12,
marginRight: 10
},

cardExpense: {
backgroundColor: "#FEE2E2",
flex: 1,
padding: 20,
borderRadius: 12
},

cardTitle: {
fontSize: 16,
color: "#555"
},

cardAmount: {
fontSize: 20,
fontWeight: "bold",
marginTop: 5
},

healthCard: {
backgroundColor: "#fff",
padding: 20,
borderRadius: 12,
alignItems: "center"
},

healthTitle: {
fontSize: 18,
marginBottom: 10
},

healthScore: {
fontSize: 28,
fontWeight: "bold",
color: "#2563EB"
}

});