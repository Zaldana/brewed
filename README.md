# Brewed Together

A cozy coffee management simulation game built in Godot 4.5, where you control three siblings managing different parts of a coffee business: farming, roasting, and serving.

## Game Overview

**Brewed Together** is a turn-based management simulation where you inherit three struggling coffee businesses and work to rebuild your grandmother's dream of "From Bean to Cup." Each day, you choose which sibling to actively manage while the others work autonomously.

## Core Features Implemented

### 🏗️ Project Architecture
- **Organized folder structure** with separate directories for scenes, scripts, resources, assets, and data
- **Autoload singletons** for core game systems (GameManager, EconomyManager, EventManager)
- **Modular design** with separate managers for each business type

### 👥 Employee System (Dwarf Fortress-style)
- **Deep personality simulation** with 12 different traits (hardworking, clumsy, creative, perfectionist, social, anxious, optimistic, lazy, intelligent, strong, artistic, organized)
- **Mood system** with 8 different mood states affecting work performance
- **Needs system** tracking rest, social interaction, fair wages, recognition, safety, challenge, and autonomy
- **Autonomous AI behavior** - employees make their own decisions based on personality and current state
- **Skill progression** with experience gain and leveling
- **Relationship system** between employees affecting workplace dynamics

### ☕ Coffee Data System
- **Coffee varieties** with different growth characteristics, flavor profiles, and market values
- **Bean lifecycle** from green beans → roasted beans → ground beans → drinks
- **Quality tracking** throughout the entire supply chain
- **Processing methods** (washed, natural, honey, semi-washed) affecting flavor
- **Inventory management** with storage limits and quality degradation over time

### 🌾 Farm System
- **Plot-based growing** with 80 individual coffee plots (10x8 grid)
- **Environmental factors** affecting crop growth (altitude, rainfall, temperature, soil quality)
- **Weather integration** with seasonal effects and random events
- **Employee tasks** including planting, harvesting, processing, watering, and maintenance
- **Equipment system** with condition tracking and maintenance needs

### 🔥 Roastery System
- **Roasting equipment** with capacity, condition, and precision tracking
- **Quality control** system for roasted beans
- **Blending recipes** for creating unique coffee blends
- **Employee tasks** including roasting, quality control, blending, packaging, and maintenance
- **Batch tracking** with roast profiles and quality scores

### 🏪 Café System
- **Customer simulation** with different types (regular, critic, tourist, business, student, coffee snob)
- **Drink recipes** with varying difficulty, price, and preparation time
- **Reputation system** affected by customer satisfaction
- **Ambiance management** including cleanliness, décor, and atmosphere
- **Employee tasks** including customer service, drink making, grinding, cleaning, and cashier duties

### 📅 Turn-Based Day System
- **Daily phase selection** where you choose which sibling to manage
- **Autonomous operation** for the other two businesses
- **Evening review** showing what happened in all businesses
- **Seasonal progression** affecting all aspects of the game

### 💰 Economy & Supply Chain
- **Dynamic market pricing** based on supply, demand, and quality
- **Internal family trading** with 20% family discount
- **External market** with NPC traders and competition
- **Supply chain management** tracking quality throughout transfers
- **Quality loss** over time and during transfers

## Technical Implementation

### Core Systems
- **GameManager**: Handles day progression, save/load, and game state
- **EconomyManager**: Manages market dynamics, pricing, and transactions
- **EventManager**: Handles weather, equipment failures, and random events
- **SupplyChainManager**: Coordinates business-to-business transfers

### Data Architecture
- **Custom Resources** for employees, coffee varieties, and beans
- **JSON data loading** for coffee variety definitions
- **Signal-based communication** between systems
- **Persistent state management** with save/load functionality

### UI System
- **Scene-based UI** with separate interfaces for each business
- **Main menu** with new game, load game, and quit options
- **Day selection screen** for choosing which sibling to manage
- **Business-specific HUDs** showing inventory, employees, and actions

## File Structure

```
brewed/
├── scenes/
│   ├── farm/FarmScene.tscn
│   ├── roastery/RoasteryScene.tscn
│   ├── cafe/CafeScene.tscn
│   └── MainScene.tscn
├── scripts/
│   ├── managers/
│   │   ├── GameManager.gd
│   │   ├── EconomyManager.gd
│   │   ├── EventManager.gd
│   │   ├── FarmManager.gd
│   │   ├── RoasteryManager.gd
│   │   ├── CafeManager.gd
│   │   └── SupplyChainManager.gd
│   └── systems/
│       ├── EmployeeAI.gd
│       ├── InventoryManager.gd
│       ├── CoffeeDataLoader.gd
│       ├── FarmPlot.gd
│       └── Customer.gd
├── resources/
│   ├── employees/Employee.gd
│   └── coffee/
│       ├── CoffeeVariety.gd
│       └── CoffeeBean.gd
├── data/json/coffee_varieties.json
└── project.godot
```

## Gameplay Loop

1. **Morning Selection**: Choose which sibling to manage for the day
2. **Day Play**: Manage your chosen business while employees work autonomously
3. **Evening Review**: See what happened in all three businesses
4. **Night Rest**: Process daily updates and prepare for the next day

## Key Design Decisions

### Dwarf Fortress-Style Employees
- Employees are **not directly controllable** - you hire them and assign roles, but they make their own decisions
- **Personality traits** create emergent gameplay as different employees behave differently
- **Mood and needs** create ongoing management challenges
- **Events and relationships** add unpredictability and depth

### Interconnected Systems
- Each business affects the others through the supply chain
- **Quality matters** throughout the entire process from farm to cup
- **Family dynamics** are reflected in internal trading discounts
- **Market forces** create external pressure and opportunities

### Cozy Management
- **Turn-based structure** allows for thoughtful decision-making
- **Autonomous operation** means you don't need to micromanage everything
- **Progressive complexity** as you learn each system
- **Narrative elements** through the grandmother's legacy story

## Current Status

The foundation of **Brewed Together** is complete with all core systems implemented. The game features:

✅ **Complete farm system** with plots, growing, and employee management  
✅ **Complete roastery system** with roasting, quality control, and blending  
✅ **Complete café system** with customers, drinks, and reputation  
✅ **Deep employee AI** with personality traits and autonomous behavior  
✅ **Turn-based day structure** with sibling selection  
✅ **Supply chain management** with internal trading  
✅ **Economy system** with dynamic pricing and external markets  
✅ **Save/load functionality** for game persistence  

## Next Steps

While the core foundation is complete, the game could be enhanced with:

- **Visual assets** (sprites, animations, UI graphics)
- **Audio system** (music, sound effects)
- **Tutorial system** and onboarding
- **Progression mechanics** (upgrades, unlocks)
- **Story elements** and narrative progression
- **Balancing and polish**

The architecture is designed to support these additions while maintaining the core gameplay loop that makes **Brewed Together** unique in the management simulation genre.
