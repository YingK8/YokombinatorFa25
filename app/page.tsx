'use client';

import { useRef, useEffect, useState } from "react";
import Image from "next/image";

export default function Home() {
  const videoRef = useRef<HTMLVideoElement>(null);
  const [error, setError] = useState<string>("");
  const [isLoading, setIsLoading] = useState(true);
  const [activeCamera, setActiveCamera] = useState<string>("");

  useEffect(() => {
    let stream: MediaStream | null = null;

    const startCamera = async () => {
      try {
        setIsLoading(true);
        setError("");

        // Get all available cameras
        const devices = await navigator.mediaDevices.enumerateDevices();
        const videoDevices = devices.filter(device => device.kind === 'videoinput');
        
        console.log('Available cameras:', videoDevices);

        // Try to find back camera first
        let constraints: MediaStreamConstraints = {
          video: {
            facingMode: { ideal: "environment" }, // Prioritize back camera
            width: { ideal: 1920 },
            height: { ideal: 1080 }
          }
        };

        // If we can identify specific cameras, try to select back camera
        if (videoDevices.length > 1) {
          // Look for cameras with "back" in label (common convention)
          const backCamera = videoDevices.find(device => 
            device.label.toLowerCase().includes('back') ||
            device.label.toLowerCase().includes('rear')
          );
          
          if (backCamera) {
            constraints = {
              video: {
                deviceId: { exact: backCamera.deviceId },
                width: { ideal: 1920 },
                height: { ideal: 1080 }
              }
            };
            setActiveCamera("Back Camera");
          } else {
            setActiveCamera("Primary Camera");
          }
        }

        stream = await navigator.mediaDevices.getUserMedia(constraints);
        
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          videoRef.current.play().catch(e => console.error('Play error:', e));
          setActiveCamera(prev => prev || "Camera");
        }
      } catch (err) {
        console.error("Error accessing camera:", err);
        setError("Unable to access preferred camera. Trying fallback...");
        
        // Fallback: try any available camera with simpler constraints
        try {
          const fallbackStream = await navigator.mediaDevices.getUserMedia({ 
            video: true 
          });
          if (videoRef.current) {
            videoRef.current.srcObject = fallbackStream;
            videoRef.current.play().catch(e => console.error('Play error:', e));
          }
          stream = fallbackStream;
          setActiveCamera("Default Camera");
          setError(""); // Clear error if fallback works
        } catch (fallbackErr) {
          setError("Camera access is not available on this device. Please check permissions.");
        }
      } finally {
        setIsLoading(false);
      }
    };

    // Check if browser supports media devices
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      setError("Camera API not supported in this browser");
      setIsLoading(false);
      return;
    }

    startCamera();

    // Cleanup function
    return () => {
      if (stream) {
        stream.getTracks().forEach(track => track.stop());
      }
    };
  }, []);

  const capturePhoto = () => {
    if (videoRef.current) {
      const canvas = document.createElement('canvas');
      const context = canvas.getContext('2d');
      if (context) {
        canvas.width = videoRef.current.videoWidth;
        canvas.height = videoRef.current.videoHeight;
        context.drawImage(videoRef.current, 0, 0);
        
        // Create download link
        const link = document.createElement('a');
        link.download = `photo-${new Date().getTime()}.png`;
        link.href = canvas.toDataURL();
        link.click();
      }
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-zinc-50 font-sans dark:bg-black">
      <main className="flex min-h-screen w-full max-w-4xl flex-col items-center justify-between py-8 px-4 bg-white dark:bg-black sm:px-8">
        {/* Header */}
        <div className="w-full text-center mb-8">
          <Image
            className="dark:invert mx-auto"
            src="/next.svg"
            alt="Next.js logo"
            width={100}
            height={20}
            priority
          />
          <h1 className="text-2xl font-bold mt-4 text-black dark:text-zinc-50">
            Camera Feed
          </h1>
          <p className="text-zinc-600 dark:text-zinc-400 mt-2">
            Back camera prioritized
          </p>
        </div>

        {/* Camera Feed Section */}
        <div className="flex-1 w-full flex flex-col items-center justify-center mb-8">
          {isLoading && (
            <div className="flex flex-col items-center justify-center w-full h-96 bg-zinc-100 dark:bg-zinc-900 rounded-lg">
              <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-blue-500 mb-4"></div>
              <p className="text-zinc-600 dark:text-zinc-400">Initializing camera...</p>
            </div>
          )}

          {error && (
            <div className="w-full max-w-md bg-red-50 dark:bg-red-900/20 border border-red-200 dark:border-red-800 rounded-lg p-6 text-center">
              <p className="text-red-600 dark:text-red-400 mb-4">{error}</p>
              <button
                onClick={() => window.location.reload()}
                className="px-4 py-2 bg-red-600 text-white rounded-lg hover:bg-red-700 transition-colors"
              >
                Try Again
              </button>
            </div>
          )}

          {!error && !isLoading && (
            <div className="w-full max-w-2xl">
              <div className="relative rounded-lg overflow-hidden shadow-lg bg-black">
                <video
                  ref={videoRef}
                  autoPlay
                  playsInline
                  muted
                  className="w-full h-auto"
                />
                <div className="absolute bottom-4 left-4 bg-black/50 text-white px-3 py-1 rounded-full text-sm">
                  {activeCamera} • Live
                </div>
              </div>
              
              {/* Camera Controls */}
              <div className="mt-6 flex justify-center space-x-4">
                <button
                  onClick={capturePhoto}
                  className="flex items-center gap-2 px-6 py-3 bg-blue-600 text-white rounded-full hover:bg-blue-700 transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 9a2 2 0 012-2h.93a2 2 0 001.664-.89l.812-1.22A2 2 0 0110.07 4h3.86a2 2 0 011.664.89l.812 1.22A2 2 0 0018.07 7H19a2 2 0 012 2v9a2 2 0 01-2 2H5a2 2 0 01-2-2V9z" />
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 13a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                  Capture Photo
                </button>
                
                <button
                  onClick={() => window.location.reload()}
                  className="flex items-center gap-2 px-6 py-3 bg-gray-600 text-white rounded-full hover:bg-gray-700 transition-colors"
                >
                  <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
                  </svg>
                  Switch Camera
                </button>
              </div>
            </div>
          )}
        </div>

        {/* Info Section */}
        <div className="w-full max-w-2xl text-center">
          <div className="bg-zinc-50 dark:bg-zinc-900 rounded-lg p-6 mb-6">
            <h2 className="text-lg font-semibold text-black dark:text-zinc-50 mb-2">
              Camera Information
            </h2>
            <p className="text-zinc-600 dark:text-zinc-400 text-sm mb-4">
              This app prioritizes the back camera (environment-facing) for mobile devices. 
              On desktop, it will use the available camera. You can capture photos and switch cameras.
            </p>
            <div className="flex justify-center items-center gap-4 text-xs text-zinc-500">
              <div className="flex items-center">
                <div className="w-2 h-2 bg-green-500 rounded-full mr-2"></div>
                Camera Active
              </div>
              <div className="flex items-center">
                <div className="w-2 h-2 bg-blue-500 rounded-full mr-2"></div>
                Back Camera Priority
              </div>
            </div>
          </div>

          {/* Action Buttons */}
          <div className="flex flex-col gap-4 text-base font-medium sm:flex-row justify-center">
            <a
              className="flex h-12 w-full items-center justify-center gap-2 rounded-full bg-foreground px-5 text-background transition-colors hover:bg-[#383838] dark:hover:bg-[#ccc] md:w-[158px]"
              href="https://nextjs.org/docs?utm_source=create-next-app&utm_medium=appdir-template-tw&utm_campaign=create-next-app"
              target="_blank"
              rel="noopener noreferrer"
            >
              <Image
                className="dark:invert"
                src="/vercel.svg"
                alt="Vercel logomark"
                width={16}
                height={16}
              />
              Documentation
            </a>
            <a
              className="flex h-12 w-full items-center justify-center rounded-full border border-solid border-black/[.08] px-5 transition-colors hover:border-transparent hover:bg-black/[.04] dark:border-white/[.145] dark:hover:bg-[#1a1a1a] md:w-[158px]"
              href="https://github.com/vercel/next.js"
              target="_blank"
              rel="noopener noreferrer"
            >
              GitHub
            </a>
          </div>
        </div>
      </main>
    </div>
  );
}