# $FreeBSD$

PORTNAME=	photoprism
DISTVERSION=	g20220616
CATEGORIES=	www

MAINTAINER=	huoju@devep.net
COMMENT=	Personal Photo Management Web Service

LICENSE=	AGPLv3

RUN_DEPENDS=  ffmpeg:multimedia/ffmpeg \
	exiftool:graphics/p5-Image-ExifTool

LIB_DEPENDS=	libtensorflow.so.1:science/libtensorflow1

EXTRACT_DEPENDS=  ${RUN_DEPENDS} \
	bash:shells/bash \
	git:devel/git \
	gmake:devel/gmake \
	go>=1.18.2:lang/go \
	npm:www/npm-node18 \
	wget:ftp/wget

BUILD_DEPENDS= ${EXTRACT_DEPENDS}

USES= gmake python:3.6+,build

USE_GITHUB=	yes
GH_ACCOUNT=	photoprism
GH_PROJECT=	photoprism
GH_TAGNAME=     0402b8d3977da9077cbae1f74e767626b7e6cc01

USE_RC_SUBR=    photoprism
PHOTOPRISM_DATA_DIR=      /var/db/photoprism
SUB_LIST+=      PHOTOPRISM_DATA_DIR=${PHOTOPRISM_DATA_DIR}
SUB_FILES+=      pkg-install pkg-message

post-extract:
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-facenet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nasnet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nsfw.sh
	@${REINPLACE_CMD} -e 's|	sudo npm install -g npm|	cd frontend \&\& env NODE_ENV=production npm install -D webpack-cli|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|dep-js:|dep-js: dep-npm|g' ${WRKSRC}/Makefile 
	@${REINPLACE_CMD} -e 's|build-js:|build-js: dep-js|g' ${WRKSRC}/Makefile 
	@${REINPLACE_CMD} -e 's|all: dep build-js|all: dep-tensorflow build-js dep-go build-go |g' ${WRKSRC}/Makefile 

pre-build:
	@${REINPLACE_CMD} -e 's|	go build -v ./...|	CGO_LDFLAGS="-L/usr/local/lib" go build -v ./cmd/... ./internal/... ./pkg/...|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|	scripts/build.sh debug|	CGO_LDFLAGS="-L/usr/local/lib" scripts/build.sh debug|g' ${WRKSRC}/Makefile

	@${REINPLACE_CMD} -e 's|BUILD_VERSION=.*|BUILD_VERSION=${GH_TAGNAME}|' ${WRKSRC}/scripts/build.sh
	@${REINPLACE_CMD} -e 's|BUILD_VERSION ?=.*|BUILD_VERSION=${GH_TAGNAME}|' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|BUILD_ARCH=.*|BUILD_ARCH=$$(uname -m)|' ${WRKSRC}/scripts/build.sh
	@${REINPLACE_CMD} -e 's|BUILD_ARCH ?=.*|BUILD_ARCH=$$(uname -m)|' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|main.version=[^"]*|main.version=${DISTVERSION:C/^...//}-${GH_TAGNAME:C/([0-9a-f]{7}).*/\1/}-$${BUILD_OS}-$${BUILD_ARCH}-DEBUG-build-$${BUILD_DATE}|' ${WRKSRC}/scripts/build.sh
	${MKDIR} ${WRKSRC}/build
	${MKDIR} ${WRKSRC}/assets/static/build

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/photoprism ${STAGEDIR}${PREFIX}/bin
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}
	${CP} -r ${WRKSRC}/assets ${STAGEDIR}${PHOTOPRISM_DATA_DIR}/assets

pre-install:
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}

.include <bsd.port.mk>
