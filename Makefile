# $FreeBSD$

PORTNAME=	photoprism
DISTVERSION=	g211215
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
	go>=1.17.5:lang/go \
	npm:www/npm-node17 \
	wget:ftp/wget

USES= gmake python:3.6+,build

USE_GITHUB=	yes
GH_ACCOUNT=	photoprism
GH_PROJECT=	photoprism
GH_TAGNAME=     93b26f197908dd825dfa302d17793185cc3eab8c

USE_RC_SUBR=    photoprism
PHOTOPRISM_DATA_DIR=      /var/db/photoprism
SUB_LIST+=      PHOTOPRISM_DATA_DIR=${PHOTOPRISM_DATA_DIR}
SUB_FILES+=      pkg-install pkg-message

post-extract:
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-facenet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nasnet.sh
	@${REINPLACE_CMD} -e 's|sha1sum|shasum|g' ${WRKSRC}/scripts/download-nsfw.sh

pre-build:
	@${REINPLACE_CMD} -e 's|	go build -v ./...|	CGO_LDFLAGS="-L/usr/local/lib" go build -v ./cmd/... ./internal/... ./pkg/...|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|	scripts/build.sh debug|	CGO_LDFLAGS="-L/usr/local/lib" scripts/build.sh debug|g' ${WRKSRC}/Makefile
	@${REINPLACE_CMD} -e 's|PHOTOPRISM_VERSION=.*|PHOTOPRISM_VERSION=${GH_TAGNAME}|' ${WRKSRC}/scripts/build.sh

do-install:
	${INSTALL_PROGRAM} ${WRKSRC}/photoprism ${STAGEDIR}${PREFIX}/bin
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}
	${CP} -r ${WRKSRC}/assets ${STAGEDIR}${PHOTOPRISM_DATA_DIR}/assets

pre-install:
	${MKDIR} ${STAGEDIR}${PHOTOPRISM_DATA_DIR}

.include <bsd.port.mk>
