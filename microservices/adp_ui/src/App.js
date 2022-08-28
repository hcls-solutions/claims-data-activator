/** This file is the starting point of the application where the route configuration is configured. 
 *  When the user is loggedin the user data is stored in the session storage to prevent the auth
 *  guards access to the other pages. If the token is found in session storage is found then the
 *  user token is found, then redirect to other pages else redirect to login page
*/

import React, { useEffect } from "react";
import {
    BrowserRouter as Router,
    Route,
    Switch, Redirect
} from 'react-router-dom';
import { ToastContainer } from 'react-toastify';
import { GlobalDebug } from "./configs/remove-console";
import Dashboard from './components/Dashboard';

import Upload from './components/Upload';
import DocumentReview from './components/DocumentReview';
import Login from "./components/Login";
import ReAssign from "./components/ReAssign";
import './App.css';
import Classified from "./components/Classify";

function App() {
useEffect(() =>{
GlobalDebug(false);
})
  return (
   <div >
          <Router> 
        <Switch>
<Route path='/login' component={Login} />
{localStorage.getItem('login') ?  
            <>
            <Route exact path="/">
              <Dashboard />
            </Route>
            <Route path="/upload">
                <Upload />
              </Route>
              <Route path="/documentreview/:uid/:caseid">
                <DocumentReview />
              </Route>
              <Route path="/classify/:uid/:caseid">
                <Classified />
              </Route>
              <Route path="/reassign">
                <ReAssign />
              </Route>
             </>: <Redirect to="/login" />}
          
        </Switch>
    </Router> 

    <ToastContainer position="bottom-center"
        autoClose={3000}
        preventDuplicated={false}
        hideProgressBar={true}
        newestOnTop={false}
        closeOnClick
        rtl={false}
        limit={1}
        pauseOnFocusLoss
        draggable
        pauseOnHover
      />
    </div>
  );
}

export default App;
