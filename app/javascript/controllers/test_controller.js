import { Controller } from "@hotwired/stimulus"

export default class extends Controller {
  connect() {
    console.log("Test controller connected")
  }
  
  sayHello() {
    alert("Hello from Test controller!")
  }
} 