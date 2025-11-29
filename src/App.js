import React, { useState } from 'react';
import './App.css';

function App() {
  const [documentHash, setDocumentHash] = useState('');
  const [metadata, setMetadata] = useState('');
  const [verificationHash, setVerificationHash] = useState('');

  const handleRegister = () => {
    // Add your registration logic here
    console.log('Registering document:', { documentHash, metadata });
  };

  const handleVerify = () => {
    // Add your verification logic here
    console.log('Verifying document:', verificationHash);
  };

  return (
    <div className="App">
      <header className="App-header">
        <h1>Document Registry</h1>
      </header>
      <main>
        <section>
          <h2>Register Document</h2>
          <input
            type="text"
            placeholder="Document Hash (bytes32)"
            value={documentHash}
            onChange={(e) => setDocumentHash(e.target.value)}
          />
          <input
            type="text"
            placeholder="Metadata"
            value={metadata}
            onChange={(e) => setMetadata(e.target.value)}
          />
          <button onClick={handleRegister}>Register</button>
        </section>
        <section>
          <h2>Verify Document</h2>
          <input
            type="text"
            placeholder="Document Hash (bytes32)"
            value={verificationHash}
            onChange={(e) => setVerificationHash(e.target.value)}
          />
          <button onClick={handleVerify}>Verify</button>
        </section>
      </main>
    </div>
  );
}

export default App;