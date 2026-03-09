import React, { useEffect, useState } from "react";
import "./LoanDashboard.css";
import API from "./api";

function LoanDashboard() {

  const [customers, setCustomers] = useState([]);
  const [accountNo, setAccountNo] = useState("");
  const [amount, setAmount] = useState("");
  const [message, setMessage] = useState("");
  const [history, setHistory] = useState([]);

  useEffect(() => {
    API.get("customers/")
      .then((res) => setCustomers(res.data))
      .catch((err) => console.log(err));
  }, []);

  const handleSubmit = (e) => {
    e.preventDefault();

    API.post("payments/", {
      account_no: accountNo,
      payment_amount: amount
    })
    .then(() => {
      setMessage("✅ Payment Successful!");
      setAccountNo("");
      setAmount("");
    })
    .catch(() => {
      setMessage("❌ Payment Failed!");
    });
  };

  const loadHistory = (account) => {
    API.get(`payments/${account}/`)
      .then((res) => setHistory(res.data))
      .catch((err) => console.log(err));
  };

  return (
    <div className="container">

      <h1 className="title">💳 Payment Collection App</h1>

      <h2>Customer Loan Details</h2>

      <table className="table">
        <thead>
          <tr>
            <th>Account Number</th>
            <th>Issue Date</th>
            <th>Interest Rate</th>
            <th>Tenure</th>
            <th>EMI Due</th>
            <th>History</th>
          </tr>
        </thead>

        <tbody>
          {customers.map((customer) => (
            <tr key={customer.account_no}>
              <td>{customer.account_no}</td>
              <td>{customer.issue_date}</td>
              <td>{customer.interest_rate}%</td>
              <td>{customer.tenure}</td>
              <td>{customer.emi_due}</td>

              <td>
                <button
                  className="history-btn"
                  onClick={() => loadHistory(customer.account_no)}
                >
                  View
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>

      <h2>Make Payment</h2>

      <form className="payment-form" onSubmit={handleSubmit}>

        <div className="input-group">
          <label>Account Number</label>
          <input
            type="text"
            value={accountNo}
            onChange={(e)=>setAccountNo(e.target.value)}
            required
          />
        </div>

        <div className="input-group">
          <label>Amount</label>
          <input
            type="number"
            value={amount}
            onChange={(e)=>setAmount(e.target.value)}
            required
          />
        </div>

        <button className="pay-btn" type="submit">Pay Now</button>

      </form>

      {message && <h3 className="message">{message}</h3>}

      <h2>Payment History</h2>

      <table className="table">
        <thead>
          <tr>
            <th>Date</th>
            <th>Amount</th>
            <th>Status</th>
          </tr>
        </thead>

        <tbody>
          {history.map((p, index) => (
            <tr key={index}>
              <td>{new Date(p.payment_date).toLocaleString()}</td>
              <td>₹{p.payment_amount}</td>
              <td>{p.status}</td>
            </tr>
          ))}
        </tbody>
      </table>

    </div>
  );
}

export default LoanDashboard;
