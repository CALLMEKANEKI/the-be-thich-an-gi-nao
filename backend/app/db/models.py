from sqlalchemy import Column, Integer, String, ForeignKey, DateTime, JSON
from sqlalchemy.sql import func
from app.db.session import Base

class User(Base):
    __tablename__ = "users"
    
    id = Column(Integer, primary_key= True, index= True)
    device_id = Column(String, unique= True, nullable= False)
    created_at= Column(DateTime(timezone= True), server_default=func.now())
    
class Dish(Base):
    __tablename__ = "dishes"
    
    id = Column(Integer, primary_key= True, index= True)
    name = Column(String, nullable= False)
    description = Column(String)
    category = Column(String)
    image_url = Column(String)
    
class SpinHistory(Base):
    __tablename__ = "spin_history"
    
    id = Column(Integer, primary_key= True, index= True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable= False)
    dish_id = Column(Integer, ForeignKey("dishes.id"), nullable= False)
    mood = Column(String)
    create_at = Column(DateTime(timezone= True), server_default= func.now())
    
class ShoppingList(Base):
    __tablename__ = "shopping_list"
    
    id = Column(Integer, primary_key= True, index= True)
    user_id = Column(Integer, ForeignKey("users.id"), nullable= False)
    dish_id = Column(Integer, ForeignKey("dishes.id"), nullable= False)
    items = Column(JSON)
    deeplink = Column(String)
    create_at = Column(DateTime(timezone= True), server_default= func.now())