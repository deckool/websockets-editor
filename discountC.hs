
import           Control.Monad
import           Text.Discount
import qualified Data.ByteString.Char8 as C
import           Control.Concurrent.Async

--main :: IO()
main = forever $ do
	withAsync getLine $ \a -> do
	b <- wait a
	--let md5 = C.pack md
	let parsed = parseMarkdown compatOptions $ C.pack b
	let answer = "---" ++ (C.unpack parsed) ++ "---"
	print answer

{--

# (GitHub-Flavored) Markdown Editorjhjhjjjjjnnjjdso\nfereeeddgffrgtttggcxfvxdgfsdgfdsg\nerjweirwiuetirwtkkk dads 

--}