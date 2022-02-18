/* This is the authentication component */
/*This is simple component using a login and sign up button to leverage the Flow JS SDK’s ability to connect to a wallet discovery provider. 
You’ll be able to sign up for an account or sign in with an existing account.*/
import React, {useState, useEffect} from 'react'
import * as fcl from "@onflow/fcl"

const AuthCluster = () => {
  const [user, setUser] = useState({loggedIn: null})
  useEffect(() => fcl.currentUser().subscribe(setUser), [])
  if (user.loggedIn) {
    return (
      <div>
        <span>{user?.addr ?? "No Address"}</span>
        <button className="btn-primary" onClick={fcl.unauthenticate}>Log Out</button>
      </div>
    )
  } else {
    return (
      <div>
        <button className="btn-primary" onClick={fcl.logIn}>Log In</button>
        <button className="btn-secondary" onClick={fcl.signUp}>Sign Up</button>
      </div>
    )
  }
}

export default AuthCluster