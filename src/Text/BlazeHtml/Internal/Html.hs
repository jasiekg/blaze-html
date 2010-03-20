{-# LANGUAGE FlexibleInstances, TypeSynonymInstances #-}
module Text.BlazeHtml.Internal.Html
    ( Attributes
    , Html (..)
    , setUnescapedAttributes
    , addUnescapedAttribute
    , addUnescapedAttributes
    , clearAttributes
    , IsAttributable((!))
    , (<!)
    ) where

import Data.Monoid
import Text.BlazeHtml.Text (Text)

infixl 2 !
infixl 2 <!
infix 1 </

-- | Attributes as an association list. 
--   Please do not rely on the fact that this is an association list - this is
--   subject to change.
type Attributes = [(Text,Text)]

-- | Function that manipulates attributes. This is used for the CPS.
type AttributeManipulation = Attributes -> Attributes

-- | Any Html document is a monoid. Furthermore, the following equalities hold.
--
--    renderUnescapedText mempty = mempty
--
--    renderUnescapedText t1 `mappend` renderUnescapedText t2 = renderText (t1 `mappend` t2)
--
--    setUnescapedAttributes a (renderUnescapedText t) = renderUnescapedText t
--
--    addUnescapedAttributes a (renderUnescapedText t) = renderUnescapedText t
--
--    setUnescapedAttributes a1 (setUnescapedAttributes a2 h) = setUnescapedAttributes a2 h
--
--    addUnescapedAttributes a1 (setUnescapedAttributes a2 h) = setUnescapedAttributes a2 h
--
--    addUnescapedAttributes a1 (addUnescapedAttributes a2 h) = addUnescapedAttributes (a2 `mappend` a1) h 
--
--    renderElement t h = renderElement t (modifyUnescapedAttributes (const []) h)
--
---------------------------------------------------------------------
--
--    The following need to be tested in a more compreensive way:
--  
--    modifyUnescapedAttributes f (t1 `mappend` t2) = 
--    modifyUnescapedAttributes t1 `mappend` modifyUnescapedAttributes t2
--
--    modifyUnescapedAttributes f (modifyUnescapedAttributes g h) = modifyUnescapedAttributes (g.f) h
--
--    modifyUnescapedAttributes f (renderUnescapedText t) = renderUnescapedText t
--
--  Note that the interface below may be extended, if a performing
--  implementation requires it.
--
class Monoid h => Html h where
    -- | Render text -- no escaping is done.
    renderUnescapedText       :: Text -> h
    -- | Render a leaf element with the given tag name.
    renderLeafElement         :: Text -> h
    -- | Render an element with the given tag name and the given inner html.
    renderElement             :: Text -> h -> h
    -- | Set the attributes of the outermost element.
    modifyUnescapedAttributes ::
        (AttributeManipulation -> AttributeManipulation) -> h -> h

-- | Set the attributes all outermost elements to the given list of
-- unescaped HTML attributes.
setUnescapedAttributes :: (Html h) => Attributes -> h -> h
setUnescapedAttributes = modifyUnescapedAttributes . (.) . const

-- | Add a single unescaped HTML attribute to all outermost elements.
--
-- > addAttribute "src" "foo.png"
addUnescapedAttributes :: (Html h) => Attributes -> h -> h
addUnescapedAttributes = modifyUnescapedAttributes . (.) . (++)

-- | Add a single HTML attribute to all outermost elements.
--
-- > addAttribute "src" "foo.png"
addUnescapedAttribute :: (Html h) => Text -> Text -> h -> h
addUnescapedAttribute key value =
    modifyUnescapedAttributes (((key, value) :) .)

-- | Remove the HTML attributes of all outermost elements.
clearAttributes :: (Html h) => h -> h
clearAttributes = setUnescapedAttributes []

-- | Add attributes to a node element.
(<!) :: (IsAttributable a, Html h) => (h -> h) -> a -> h -> h
el <! a = \inner -> (el inner) ! a

-- | Build a node element with a list of inner HTML documents.
(</) :: (Html h) => (h -> h) -> [h] -> h
el </ inner = el (mconcat inner)

-- | A class for specifying how to use a specific type to set attributes.  
-- We use this to allow the operator (!) to set both a single attribute 
-- and a list of attributes.
class IsAttributable q where
    (!) :: Html h => h -> q -> h

-- | IsAttributable instance for a single Attribute
instance IsAttributable (Text,Text) where
    e ! attr = addUnescapedAttributes [attr] e

-- | IssAttributatable instance for a list of Attributes
instance IsAttributable [(Text,Text)] where
    e ! attrs = addUnescapedAttributes attrs e
