import { Controller } from "@hotwired/stimulus"

// Version: 2023-06-14-001
export default class extends Controller {
  static targets = ["cityButton", "cityMenu", "clubButton", "clubMenu", "clubsContainer"]
  
  connect() {
    console.log("Dashboard controller connected - v2")
    this.setupDropdowns()
    
    // Close dropdowns when clicking outside
    document.addEventListener('click', (e) => {
      if (!e.target.closest('.dropdown')) {
        this.closeAllDropdowns()
      }
    })
  }
  
  setupDropdowns() {
    console.log("Setting up dropdowns")
    // Set up city dropdown
    this.cityButtonTarget.addEventListener('click', (e) => {
      e.preventDefault()
      e.stopPropagation()
      
      const isExpanded = this.cityButtonTarget.getAttribute('aria-expanded') === 'true'
      
      if (isExpanded) {
        this.closeAllDropdowns()
      } else {
        this.closeAllDropdowns()
        this.cityMenuTarget.classList.remove('hidden')
        this.cityMenuTarget.classList.add('show')
        this.cityButtonTarget.setAttribute('aria-expanded', 'true')
        this.cityButtonTarget.querySelector('svg').style.transform = 'rotate(180deg)'
      }
    })
    
    // Set up city dropdown items
    this.cityMenuTarget.querySelectorAll('.dropdown-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()
        
        // Remove data-selected from all items
        this.cityMenuTarget.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
        // Set data-selected on clicked item
        item.setAttribute('data-selected', 'true')
        
        this.cityButtonTarget.querySelector('span').textContent = item.textContent
        this.closeAllDropdowns()
        this.handleCitySelection(item.dataset.value)
      })
    })
    
    // Set up club dropdown
    this.clubButtonTarget.addEventListener('click', (e) => {
      e.preventDefault()
      e.stopPropagation()
      
      const isExpanded = this.clubButtonTarget.getAttribute('aria-expanded') === 'true'
      
      if (isExpanded) {
        this.closeAllDropdowns()
      } else {
        this.closeAllDropdowns()
        this.clubMenuTarget.classList.remove('hidden')
        this.clubMenuTarget.classList.add('show')
        this.clubButtonTarget.setAttribute('aria-expanded', 'true')
        this.clubButtonTarget.querySelector('svg').style.transform = 'rotate(180deg)'
      }
    })
    
    // Set up club dropdown items
    this.clubMenuTarget.querySelectorAll('.dropdown-item').forEach(item => {
      item.addEventListener('click', (e) => {
        e.preventDefault()
        e.stopPropagation()
        
        // Remove data-selected from all items
        this.clubMenuTarget.querySelectorAll('.dropdown-item').forEach(i => i.removeAttribute('data-selected'))
        // Set data-selected on clicked item
        item.setAttribute('data-selected', 'true')
        
        this.clubButtonTarget.querySelector('span').textContent = item.textContent
        this.closeAllDropdowns()
        this.handleClubSelection(item.dataset.value, item.dataset.city)
      })
    })
  }
  
  closeAllDropdowns() {
    document.querySelectorAll('.dropdown-menu').forEach(menu => {
      menu.classList.add('hidden')
      menu.classList.remove('show')
      const btn = menu.previousElementSibling
      if (btn) {
        btn.setAttribute('aria-expanded', 'false')
        const arrow = btn.querySelector('svg')
        if (arrow) arrow.style.transform = ''
      }
    })
  }
  
  handleCitySelection(cityValue) {
    // Show clubs container
    this.clubsContainerTarget.classList.toggle('hidden', !cityValue)
    
    // Reset club dropdown text
    this.clubButtonTarget.querySelector('span').textContent = 'Select a club...'
    
    // Filter club dropdown items
    const clubItems = this.clubMenuTarget.querySelectorAll('.dropdown-item')
    clubItems.forEach(item => {
      const showOption = !cityValue || item.dataset.city === cityValue
      item.closest('li').style.display = showOption ? '' : 'none'
    })
  }
  
  handleClubSelection(clubId, cityName) {
    // Load classes for this club
    this.loadClasses(clubId, cityName)
  }
  
  loadClasses(clubId, cityName) {
    console.log(`Loading classes for club ${clubId} in ${cityName}`)
    
    // Get the Turbo Frame element
    const weeklyClassesFrame = document.getElementById('weekly-classes-container')
    
    // Set the src attribute to load classes for the selected club
    if (weeklyClassesFrame) {
      weeklyClassesFrame.setAttribute('src', `/weekly_classes?club_id=${clubId}`)
      
      // Make the frame visible if it was hidden
      weeklyClassesFrame.classList.remove('hidden')
    } else {
      console.error('Could not find weekly-classes-container element')
    }
  }
  
  sayHello() {
    alert("Hello from Stimulus! Updated version")
    console.log("sayHello method called")
  }
} 