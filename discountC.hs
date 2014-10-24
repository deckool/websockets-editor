
import           Control.Monad
import           Text.Discount
import qualified Data.ByteString.Char8 as C
import           Control.Concurrent.Async

--main :: IO()
main = do
	a <- getLine
	--let md5 = C.pack md
	let parsed = parseMarkdown compatOptions $ C.pack a
	let answer = "---" ++ (C.unpack parsed) ++ "---"
	print parsed

{--

# (GitHub-Flavored) Markdown Editorjhjhjjjjjnnjjdso\nfereeeddgffrgtttggcxfvxdgfsdgfdsg\nerjweirwiuetirwtkkk dads 

--}