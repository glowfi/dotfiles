#!/bin/bash

## Screenshot function
takeScreenshot() {
	SCREENSHOTDIR="${HOME}/Pictures/ScreenShots"
	mkdir -p "${SCREENSHOTDIR}"
	SCREENSHOTNAME="${SCREENSHOTDIR}/$(date '+%d-%m-%Y_%H-%M-%S').png"

	if [[ "$XDG_CURRENT_DESKTOP" == "KDE" ]]; then
		spectacle -b -r -n -o "${SCREENSHOTNAME}" || exit 1
	else
		geom=$(slurp) || exit 1
		grim -g "$geom" "${SCREENSHOTNAME}" || exit 1
	fi

	for _ in $(seq 1 50); do
		[[ -s "$SCREENSHOTNAME" ]] && return 0
		sleep 0.1
	done
	notify-send "Screenshot failed"
	exit 1
}

## [Extract Text] By [Taking screenshot]
callTesseractScreenshot() {
	takeScreenshot
	extractedText=$(tesseract "$SCREENSHOTNAME" -)
	if [[ "$extractedText" != "" ]]; then
		echo "$extractedText" | wl-copy
		notify-send "Extracted Text copied to clipboard!"
	fi
}

## [Extract Text] By [Taking screenshot] [Multilang]
multiLangTesseractScreenshot() {
	takeScreenshot
	getLang=$(printf "afr Afrikaans\namh Amharic\nara Arabic\nasm Assamese\naze Azerbaijani\naze_cyrl Azerbaijani\nbel Belarusian\nben Bengali\nbod Tibetan\nbos Bosnian\nbre Breton\nbul Bulgarian\ncat Catalan\nceb Cebuano\nces Czech\nchi_sim Chinese\nchi_tra Chinese\nchr Cherokee\ncos Corsican\ncym Welsh\ndan Danish\ndan_frak Danish\ndeu German\ndeu_frak German\ndzo Dzongkha\nell Greek\neng English\nenm English\nepo Esperanto\nequ Math\nest Estonian\neus Basque\nfao Faroese\nfas Persian\nfil Filipino\nfin Finnish\nfra French\nfrk German\nfrm French\nfry Western\ngla Scottish\ngle Irish\nglg Galician\ngrc Greek\nguj Gujarati\nhat Haitian\nheb Hebrew\nhin Hindi\nhrv Croatian\nhun Hungarian\nhye Armenian\niku Inuktitut\nind Indonesian\nisl Icelandic\nita Italian\nita_old Italian\njav Javanese\njpn Japanese\nkan Kannada\nkat Georgian\nkat_old Georgian\nkaz Kazakh\nkhm Central\nkir Kirghiz\nkmr Kurmanji\nkor Korean\nkor_vert Korean\nkur Kurdish\nlao Lao\nlat Latin\nlav Latvian\nlit Lithuanian\nltz Luxembourgish\nmal Malayalam\nmar Marathi\nmkd Macedonian\nmlt Maltese\nmon Mongolian\nmri Maori\nmsa Malay\nmya Burmese\nnep Nepali\nnld Dutch\nnor Norwegian\noci Occitan\nori Oriya\nosd Orientation\npan Panjabi\npol Polish\npor Portuguese\npus Pushto\nque Quechua\nron Romanian\nrus Russian\nsan Sanskrit\nsin Sinhala\nslk Slovak\nslk_frak Slovak\nslv Slovenian\nsnd Sindhi\nspa Spanish\nspa_old Spanish\nsqi Albanian\nsrp Serbian\nsrp_latn Serbian\nsun Sundanese\nswa Swahili\nswe Swedish\nsyr Syriac\ntam Tamil\ntat Tatar\ntel Telugu\ntgk Tajik\ntgl Tagalog\ntha Thai\ntir Tigrinya\nton Tonga\ntur Turkish\nuig Uighur\nukr Ukrainian\nurd Urdu\nuzb Uzbek\nuzb_cyrl Uzbek\nvie Vietnamese\nyid Yiddish\nyor Yoruba" | bemenu -i -l 10 -p "Choose Language:" | awk -F" " '{print $1}')
	extractedText=$(tesseract -l "$getLang" "$SCREENSHOTNAME" -)
	if [[ "$extractedText" != "" ]]; then
		echo "$extractedText" | wl-copy
		notify-send "Extracted Text copied to clipboard!"
	fi
}

## [Extract Text] direct [from an image file]
callTesseractImageFile() {
	getFile=$(fd --exclude "$HOME/go" --type file --print0 --max-depth 3 --full-path "$HOME" | xargs -0 -I{} stat --format "%Y %n" "{}" | sort -rn | bemenu -i -l 20 | awk -F" " '{print $2}')
	fileLocation=$(realpath "$getFile")

	if [[ "$getFile" != "" ]]; then
		extractedText=$(tesseract "$fileLocation" -)
		if [[ "$extractedText" != "" ]]; then
			echo "$extractedText" | wl-copy
			notify-send "Extracted Text copied to clipboard!"
		fi
	fi
}

## [Extract Text] direct [from an image file] [Multilang]
callTesseractImageFileMulti() {
	getFile=$(fd --exclude "$HOME/go" --type file --print0 --max-depth 3 --full-path "$HOME" | xargs -0 -I{} stat --format "%Y %n" "{}" | sort -rn | bemenu -i -l 20 | awk -F" " '{print $2}')
	fileLocation=$(realpath "$getFile")

	if [[ "$getFile" != "" ]]; then
		getLang=$(printf "afr Afrikaans\namh Amharic\nara Arabic\nasm Assamese\naze Azerbaijani\naze_cyrl Azerbaijani\nbel Belarusian\nben Bengali\nbod Tibetan\nbos Bosnian\nbre Breton\nbul Bulgarian\ncat Catalan\nceb Cebuano\nces Czech\nchi_sim Chinese\nchi_tra Chinese\nchr Cherokee\ncos Corsican\ncym Welsh\ndan Danish\ndan_frak Danish\ndeu German\ndeu_frak German\ndzo Dzongkha\nell Greek\neng English\nenm English\nepo Esperanto\nequ Math\nest Estonian\neus Basque\nfao Faroese\nfas Persian\nfil Filipino\nfin Finnish\nfra French\nfrk German\nfrm French\nfry Western\ngla Scottish\ngle Irish\nglg Galician\ngrc Greek\nguj Gujarati\nhat Haitian\nheb Hebrew\nhin Hindi\nhrv Croatian\nhun Hungarian\nhye Armenian\niku Inuktitut\nind Indonesian\nisl Icelandic\nita Italian\nita_old Italian\njav Javanese\njpn Japanese\nkan Kannada\nkat Georgian\nkat_old Georgian\nkaz Kazakh\nkhm Central\nkir Kirghiz\nkmr Kurmanji\nkor Korean\nkor_vert Korean\nkur Kurdish\nlao Lao\nlat Latin\nlav Latvian\nlit Lithuanian\nltz Luxembourgish\nmal Malayalam\nmar Marathi\nmkd Macedonian\nmlt Maltese\nmon Mongolian\nmri Maori\nmsa Malay\nmya Burmese\nnep Nepali\nnld Dutch\nnor Norwegian\noci Occitan\nori Oriya\nosd Orientation\npan Panjabi\npol Polish\npor Portuguese\npus Pushto\nque Quechua\nron Romanian\nrus Russian\nsan Sanskrit\nsin Sinhala\nslk Slovak\nslk_frak Slovak\nslv Slovenian\nsnd Sindhi\nspa Spanish\nspa_old Spanish\nsqi Albanian\nsrp Serbian\nsrp_latn Serbian\nsun Sundanese\nswa Swahili\nswe Swedish\nsyr Syriac\ntam Tamil\ntat Tatar\ntel Telugu\ntgk Tajik\ntgl Tagalog\ntha Thai\ntir Tigrinya\nton Tonga\ntur Turkish\nuig Uighur\nukr Ukrainian\nurd Urdu\nuzb Uzbek\nuzb_cyrl Uzbek\nvie Vietnamese\nyid Yiddish\nyor Yoruba" | bemenu -i -l 10 -p "Choose Language:" | awk -F" " '{print $1}')
		extractedText=$(tesseract -l "$getLang" "$fileLocation" -)
		if [[ "$extractedText" != "" ]]; then
			echo "$extractedText" | wl-copy
			notify-send "Extracted Text copied to clipboard!"
		fi
	fi
}

### Take Input
choosen=$(printf "1.[Extract Text] By [Taking screenshot]
2.[Extract Text] By [Taking screenshot] [Multilang]
3.[Extract Text] direct [from an image file]
4.[Extract Text] direct [from an image file] [Multilang]
" | bemenu -i -p "Choose:")
choosen=$(echo "$choosen" | awk -F"." '{print $1}' | xargs)

### Handle Choosen
if [[ "$choosen" = "1" ]]; then
	callTesseractScreenshot
elif [[ "$choosen" = "2" ]]; then
	multiLangTesseractScreenshot
elif [[ "$choosen" = "3" ]]; then
	callTesseractImageFile
elif [[ "$choosen" = "4" ]]; then
	callTesseractImageFileMulti
fi
