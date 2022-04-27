package jav

import (
	"DBImageCache/config"
	"DBImageCache/logger"
	"errors"
	"golang.org/x/sync/errgroup"
	"io"
	"net/http"
	"os"
	"strconv"
	"strings"
	"time"
)

var downloadTime = 60 * time.Second
var connectTime = 20 * time.Second

var VRLists = map[string]bool{
	"BIBIVR":   true,
	"KBVR":     true,
	"MAXVRH":   true,
	"TVTM":     true,
	"WVR":      true,
	"PYDVR":    true,
	"PPVR":     true,
	"HUNVR":    true,
	"CJVR":     true,
	"MLVR":     true,
	"DECOP":    true,
	"PRDVR":    true,
	"QVRT":     true,
	"PXVR":     true,
	"KIWVRB":   true,
	"YPY":      true,
	"FSVSS":    true,
	"DOVR":     true,
	"FSVR":     true,
	"HAY":      true,
	"CCVB":     true,
	"GOPJ":     true,
	"VRVR":     true,
	"MRVR":     true,
	"WFBVR":    true,
	"MANIVR":   true,
	"DECHA":    true,
	"FTVR":     true,
	"SIVR":     true,
	"TMAVR":    true,
	"SLVR":     true,
	"HOTVR":    true,
	"VRVRW":    true,
	"WOW":      true,
	"3DSVR":    true,
	"BFKB":     true,
	"CAREM":    true,
	"CLVR":     true,
	"KMVR":     true,
	"HHHVR":    true,
	"MIVR":     true,
	"ROYVR":    true,
	"XBVR":     true,
	"VRVRP":    true,
	"AJVRBX":   true,
	"MTBVR":    true,
	"KOLVRB":   true,
	"CAFUKU":   true,
	"NK":       true,
	"VRGL":     true,
	"MAXAVRF":  true,
	"FKONE":    true,
	"FKHUNT":   true,
	"VOSF":     true,
	"VVVR":     true,
	"VRSPFUKU": true,
	"NGVR":     true,
	"URVRSP":   true,
	"EBVR":     true,
	"GUNM":     true,
	"MTVR":     true,
	"REDVR":    true,
	"EXVR":     true,
	"NKKVR":    true,
	"MAXVR":    true,
	"OYCVR":    true,
	"CAPI":     true,
	"ATVR":     true,
	"CRVR":     true,
	"JPSVR":    true,
	"CABE":     true,
	"KIWVR":    true,
	"DFBVR":    true,
	"FCVR":     true,
	"PRVR":     true,
	"CASMANI":  true,
	"RVR":      true,
	"AJVR":     true,
	"CAFR":     true,
	"CVPS":     true,
	"DSVR":     true,
	"EIN":      true,
	"CCVR":     true,
	"HNVR":     true,
	"IPVR":     true,
	"JUVR":     true,
	"KAVR":     true,
	"KIVR":     true,
	"MDVR":     true,
	"NHVR":     true,
	"OVVR":     true,
	"VKVR":     true,
	"VRKM":     true,
	"WAVR":     true,
	"WPVR":     true,
	"TPVR":     true,
	"BUZX":     true,
	"COSVR":    true,
	"TPRM":     true,
	"VOSM":     true,
	"SAVR":     true,
	"HVR":      true,
	"CAIM":     true,
	"BNVR":     true,
	"SCVR":     true,
	"OPVR":     true,
	"AVERV":    true,
	"DORI":     false,
	"HIND":     true,
	"ANDYHQVR": true,
	"SLR":      true,
	"C":        false,
	"DTVR":     true,
	"VRXSVR":   true,
	"KOMZ":     true,
	"SPVR":     true,
	"CACA":     true,
	"CAMI":     true,
	"CBIKMV":   true,
	"EXDP":     true,
	"DAVR":     true,
	"COSBVR":   true,
}

func IsBlockJav(javID string) bool {
	index := strings.LastIndexAny(javID, "-")
	if index < 0 {
		panic("javID error:" + javID)
	}

	return VRLists[javID[:index]]
}

type JavImger interface {
	Search() (url string, err error)
}

var (
	ErrNotFound       = errors.New("jav not found")
	ErrDownloadFailed = errors.New("jav download failed")
)

func SaveImage(filePath string, content io.Reader) (written int64) {
	file, err := os.Create(filePath)
	if err != nil {
		return
	}
	defer file.Close()
	// Use io.Copy to just dump the response body to the file. This supports huge files
	written, err = io.Copy(file, content)
	if err != nil {
		return
	}
	return
}

func DownloadImage(url, filePath, javID string) *errgroup.Group {
	//done := make(chan error, 1)
	var g errgroup.Group

	fileName := javID + ".jpg"
	g.Go(func() error {

		client := http.Client{Timeout: downloadTime}

		response, err := client.Get(url)
		if err != nil {
			return err
		}

		defer response.Body.Close()

		if response.StatusCode != http.StatusOK {
			if response.StatusCode == http.StatusNotFound {
				return ErrNotFound
			} else {
				return ErrDownloadFailed
			}
		}

		contentLength, _ := strconv.ParseInt(response.Header.Get("Content-Length"), 10, 64)
		if contentLength < 30000 {
			return ErrNotFound
		}
		if contentLength != SaveImage(config.ImgPath()+"temp/"+fileName, response.Body) {
			//放弃临时文件夹的文件
			os.Remove(config.ImgPath() + "temp/" + fileName)
			return nil
		}
		//将临时文件夹的文件复制的static里
		err = os.Rename(config.ImgPath()+"temp/"+fileName, filePath+fileName)
		if err != nil {
			logger.Error(fileName + " file move error: " + err.Error())
			return err
		}
		return nil
	})
	return &g
}
